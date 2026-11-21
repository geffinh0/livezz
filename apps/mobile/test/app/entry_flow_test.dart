import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/app/app.dart';
import 'package:livezz_mobile/app/providers.dart';
import 'package:livezz_mobile/app/router.dart';
import 'package:livezz_mobile/app/routes.dart';
import 'package:livezz_mobile/core/auth/pending_action.dart';
import 'package:livezz_mobile/core/auth/secure_store.dart';
import 'package:livezz_mobile/core/auth/session.dart';
import 'package:livezz_mobile/core/config/data/key_value_store.dart';
import 'package:livezz_mobile/features/entry/domain/entry_decision.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/harness.dart';

class Server {
  Map<String, dynamic> config = sampleConfig();
  String? country;
  bool deviceBlocked = false;
  final devicesPosted = <Object?>[];

  ResponseBody handle(RequestOptions o) {
    if (country != null && o.path != '/config') {
      return jsonBody(403, {
        'error': {
          'code': 'regiao_bloqueada',
          'details': {'country': country},
        },
      });
    }
    if (o.path == '/devices') {
      devicesPosted.add(o.data);
      return jsonBody(201, {
        'deviceId': 'srv-device',
        'deviceSecret': 'srv-secret',
        'blocked': deviceBlocked,
        if (deviceBlocked) 'protocol': 'P-ABCD1234',
      });
    }
    return jsonBody(200, {
      ...config,
      'region': {'country': country ?? 'BR', 'allowed': country == null},
    });
  }
}

void main() {
  late Server server;
  late MemoryStore store;
  late MemorySecureStore secure;

  Future<void> pumpApp(
    WidgetTester t, {
    List<Override> extra = const [],
  }) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final adapter = StubAdapter(server.handle);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(adapter),
          keyValueStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(secure),
          ...extra,
        ],
        child: const LivezzApp(),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  /// Espera rede falsa + animação de troca de página.
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 60));
    }
  }

  setUp(() {
    server = Server();
    store = MemoryStore();
    secure = MemorySecureStore();
  });

  testWidgets('primeira abertura: boas-vindas e registra o aparelho', (
    t,
  ) async {
    await pumpApp(t);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Explorar sem conta'), findsOneWidget);
    expect(server.devicesPosted, hasLength(1));
    expect(secure.data['device.id'], 'srv-device');
    expect(secure.data['device.secret'], 'srv-secret');
  });

  testWidgets('explorar sem conta vai para Descobrir e lembra a escolha', (
    t,
  ) async {
    await pumpApp(t);
    await t.tap(find.text('Explorar sem conta'));
    await settle(t);
    expect(find.text('Descobrir'), findsWidgets);
    expect(store.data['entry.visitorMode'], '1');
  });

  testWidgets('Entrar mostra só os métodos ligados nas flags', (t) async {
    server.config = {
      ...sampleConfig(),
      'flags': {'loginPhone': true, 'loginEmail': false, 'loginGoogle': true},
    };
    await pumpApp(t);
    await t.tap(find.text('Entrar'));
    await settle(t);
    expect(find.text('Continuar com telefone'), findsOneWidget);
    expect(find.text('Continuar com e-mail'), findsNothing);
    expect(find.text('Continuar com Google'), findsOneWidget);
    expect(find.text('Este app é só para maiores de 18 anos.'), findsOneWidget);
  });

  testWidgets('visitante tocando em Perfil abre o pedido de conta (ENT17)', (
    t,
  ) async {
    store.data['entry.visitorMode'] = '1';
    await pumpApp(t);
    await t.tap(find.text('Perfil'));
    await settle(t);
    expect(find.text('Entre para continuar'), findsOneWidget);
  });

  testWidgets('ação pendente continua depois de entrar (ENT17)', (t) async {
    store.data['entry.visitorMode'] = '1';
    await pumpApp(t);
    await t.tap(find.text('Mensagens'));
    await settle(t);
    final container = ProviderScope.containerOf(
      t.element(find.byType(LivezzApp)),
    );
    await t.tap(find.text('Entrar').last); // vai para o login pelo sheet
    await settle(t);
    container.read(sessionProvider.notifier).set(const Session(userId: 'u'));
    await settle(t);
    expect(
      container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      Routes.messages,
    );
  });

  testWidgets(
    'fechar o pedido de conta descarta a ação (não roda num login depois)',
    (t) async {
      store.data['entry.visitorMode'] = '1';
      await pumpApp(t);
      await t.tap(find.text('Mensagens'));
      await settle(t);
      final container = ProviderScope.containerOf(
        t.element(find.byType(LivezzApp)),
      );
      await t.tapAt(const Offset(10, 10)); // fecha sem entrar
      await settle(t);
      expect(container.read(pendingActionProvider), isNull);
      container.read(sessionProvider.notifier).set(const Session(userId: 'u'));
      await settle(t);
      expect(
        container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        Routes.discover,
      );
    },
  );

  testWidgets('Seguindo para visitante mostra convite (Q-49)', (t) async {
    store.data['entry.visitorMode'] = '1';
    await pumpApp(t);
    await t.tap(find.text('Seguindo'));
    await settle(t);
    expect(find.text('Entre para ver quem você segue'), findsOneWidget);
    expect(find.text('Entre para continuar'), findsNothing);
  });

  testWidgets('aparelho marcado por menor abre direto o bloqueio (ENT10)', (
    t,
  ) async {
    // Já registrado antes: mesmo assim atualiza ao abrir e descobre a marca.
    secure.data.addAll({
      'device.id': 'srv-device',
      'device.secret': 'srv-secret',
    });
    server.deviceBlocked = true;
    await pumpApp(t);
    await settle(t);
    expect(find.bySemanticsIdentifier('minor.blocked'), findsOneWidget);
    expect(find.textContaining('P-ABCD1234'), findsOneWidget);
    expect(find.textContaining('suporte@'), findsOneWidget);
    expect(find.text('Criar conta'), findsNothing);
  });

  testWidgets('fora da região mostra o portão de região (ENT18)', (t) async {
    server.country = 'PT';
    await pumpApp(t);
    expect(find.byKey(const ValueKey('gate.region')), findsOneWidget);
  });

  testWidgets('manutenção: portão e "tentar de novo" libera', (t) async {
    server.config = sampleConfig(maintenance: true);
    await pumpApp(t);
    expect(find.byKey(const ValueKey('gate.maintenance')), findsOneWidget);
    server.config = sampleConfig();
    await t.tap(find.text('Tentar de novo'));
    await settle(t);
    expect(find.byKey(const ValueKey('gate.maintenance')), findsNothing);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('versão mínima maior abre o portão de atualização', (t) async {
    server.config = sampleConfig(minAppVersion: '99.0.0');
    await pumpApp(t);
    expect(find.byKey(const ValueKey('gate.update')), findsOneWidget);
  });

  testWidgets('barra em fonte 2x e RTL sem overflow', (t) async {
    store.data['entry.visitorMode'] = '1';
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(t);
    expect(t.takeException(), isNull);
  });

  test('redirectFor: tabela de rotas', () {
    expect(
      redirectFor(EntryDestination.welcome, Routes.discover),
      Routes.welcome,
    );
    expect(redirectFor(EntryDestination.welcome, Routes.entry), isNull);
    expect(redirectFor(EntryDestination.welcome, '/legal/terms'), isNull);
    expect(redirectFor(EntryDestination.home, Routes.welcome), Routes.discover);
    expect(redirectFor(EntryDestination.home, Routes.profile), isNull);
    expect(redirectFor(EntryDestination.home, Routes.entry), Routes.discover);
    expect(redirectFor(EntryDestination.visitorHome, Routes.entry), isNull);
    expect(
      redirectFor(EntryDestination.visitorHome, Routes.welcome),
      Routes.discover,
    );
    expect(
      redirectFor(EntryDestination.maintenance, Routes.discover),
      Routes.gate,
    );
    expect(redirectFor(EntryDestination.splash, Routes.welcome), Routes.start);
    // Cadastro (plano 1c) e bloqueio de menor (ENT10).
    expect(
      redirectFor(EntryDestination.onboardingProfile, Routes.discover),
      Routes.onboardingProfile,
    );
    expect(
      redirectFor(
        EntryDestination.onboardingUsername,
        Routes.onboardingProfile,
      ),
      Routes.onboardingUsername,
    );
    expect(
      redirectFor(EntryDestination.home, Routes.onboardingInterests),
      Routes.discover,
    );
    expect(
      redirectFor(EntryDestination.minorBlocked, '/legal/terms'),
      Routes.minorBlocked,
    );
    expect(
      redirectFor(EntryDestination.home, Routes.minorBlocked),
      Routes.discover,
    );
    expect(
      redirectFor(EntryDestination.visitorHome, Routes.onboardingProfile),
      Routes.discover,
    );
  });
}

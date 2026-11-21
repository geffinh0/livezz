import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/app/app.dart';
import 'package:livezz_mobile/app/providers.dart';
import 'package:livezz_mobile/app/router.dart';
import 'package:livezz_mobile/app/routes.dart';
import 'package:livezz_mobile/core/auth/secure_store.dart';
import 'package:livezz_mobile/core/auth/session.dart';
import 'package:livezz_mobile/core/auth/token_source.dart';
import 'package:livezz_mobile/core/config/data/key_value_store.dart';
import 'package:livezz_mobile/core/realtime/envelope.dart';
import 'package:livezz_mobile/core/realtime/realtime_client.dart';

import '../helpers/harness.dart';

class FakeRealtime extends RealtimeClient {
  FakeRealtime()
    : super(uri: Uri.parse('ws://x'), tokens: const NoTokenSource());
  final _events = StreamController<Envelope>.broadcast();
  @override
  Stream<Envelope> on(String type) =>
      _events.stream.where((e) => e.type == type);
  void emit(String type, Map<String, dynamic> data) => _events.add(
    Envelope(
      v: 1,
      id: '$type-${DateTime.now().microsecond}',
      type: type,
      ts: DateTime.now(),
      data: data,
    ),
  );
}

void main() {
  late MemoryStore store;
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester t, {List<dynamic> extra = const []}) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    store = MemoryStore()..data['entry.visitorMode'] = '1';
    final adapter = StubAdapter(
      (RequestOptions o) => o.path == '/devices'
          ? jsonBody(201, {'deviceId': 'd', 'deviceSecret': 's'})
          : jsonBody(200, sampleConfig()),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(adapter),
          keyValueStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(MemorySecureStore()),
          ...extra.cast(),
        ],
        child: const LivezzApp(),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 60));
    }
    container = ProviderScope.containerOf(t.element(find.byType(LivezzApp)));
  }

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 60));
    }
  }

  String path() => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .path;

  testWidgets('voltar em outra aba vai para Descobrir (Q-48)', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Seguindo'));
    await settle(t);
    expect(path(), Routes.following);
    await t.binding.handlePopRoute();
    await settle(t);
    expect(path(), Routes.discover);
  });

  testWidgets('em Descobrir: 1º voltar avisa, 2º em até 2 s sai (Q-48)', (
    t,
  ) async {
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    await pumpApp(t);
    await t.binding.handlePopRoute();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Toque de novo para sair'), findsOneWidget);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    await t.binding.handlePopRoute();
    await t.pump(const Duration(milliseconds: 100));
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('voltar depois de 2 s só avisa de novo', (t) async {
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    await pumpApp(t);
    await t.binding.handlePopRoute();
    await t.pump(const Duration(seconds: 3));
    await t.binding.handlePopRoute();
    await t.pump(const Duration(milliseconds: 100));
    expect(calls, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('cada aba mantém sua posição ao trocar (estado por aba)', (
    t,
  ) async {
    await pumpApp(t);
    container.read(sessionProvider.notifier).set(const Session(userId: 'u'));
    await settle(t);
    await t.tap(find.text('Perfil'));
    await settle(t);
    expect(path(), Routes.profile);
    await t.tap(find.text('Descobrir'));
    await settle(t);
    await t.tap(find.text('Perfil'));
    await settle(t);
    expect(path(), Routes.profile);
  });

  testWidgets('contador de mensagens segue o evento unread.updated', (t) async {
    final rt = FakeRealtime();
    await pumpApp(t, extra: [realtimeClientProvider.overrideWithValue(rt)]);
    container.read(sessionProvider.notifier).set(const Session(userId: 'u'));
    await settle(t);
    rt.emit('unread.updated', {'messages': 3, 'notifications': 0});
    await settle(t);
    expect(find.text('3'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('3 mensagens não lidas')),
      findsOneWidget,
    );
    container.read(sessionProvider.notifier).set(null);
    await settle(t);
    expect(find.text('3'), findsNothing);
  });
}

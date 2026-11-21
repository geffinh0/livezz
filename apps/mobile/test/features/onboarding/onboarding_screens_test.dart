import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/app/providers.dart';
import 'package:livezz_mobile/core/errors/app_failure.dart';
import 'package:livezz_mobile/core/http/app_gate.dart';
import 'package:livezz_mobile/features/entry/presentation/minor_blocked_screen.dart';
import 'package:livezz_mobile/features/onboarding/application/onboarding_flow.dart';
import 'package:livezz_mobile/features/onboarding/data/profile_api.dart';
import 'package:livezz_mobile/features/onboarding/presentation/interests_step_screen.dart';
import 'package:livezz_mobile/features/onboarding/presentation/profile_step_screen.dart';
import 'package:livezz_mobile/features/onboarding/presentation/username_step_screen.dart';
import 'package:livezz_mobile/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/harness.dart';

/// Fluxo falso do cadastro: registra chamadas e responde o que o teste quiser.
class FakeOnboardingFlow extends OnboardingFlow {
  FakeOnboardingFlow(super.ref);
  Object? error;
  final calls = <String>[];
  UsernameCheck Function(String u) onCheck = (u) =>
      const UsernameCheck(available: true);
  List<Interest> list = [
    for (var i = 0; i < 12; i++) Interest(id: 'i$i', name: 'Interesse $i'),
  ];

  @override
  Future<void> saveProfile({
    required String displayName,
    required DateTime birthDate,
    String? gender,
  }) async {
    calls.add('profile:$displayName:${birthDate.year}:$gender');
    if (error != null) throw error!;
  }

  @override
  Future<UsernameCheck> checkUsername(String u) async {
    calls.add('check:$u');
    return onCheck(u);
  }

  @override
  Future<void> setUsername(String u) async {
    calls.add('set:$u');
    if (error != null) throw error!;
  }

  @override
  Future<List<Interest>> interests() async {
    if (error != null) throw error!;
    return list;
  }

  @override
  Future<void> setInterests(List<String> ids) async {
    calls.add('interests:${ids.join(',')}');
  }
}

final _pt = lookupAppLocalizations(const Locale('pt'));

void main() {
  late FakeOnboardingFlow flow;
  late ProviderContainer container;

  Future<void> show(
    WidgetTester t,
    Widget screen, {
    Locale locale = const Locale('pt'),
    double textScale = 1,
    void Function(FakeOnboardingFlow f)? setup,
  }) async {
    final adapter = StubAdapter((o) => jsonBody(200, sampleConfig()));
    await t.pumpWidget(
      harness(
        screen,
        locale: locale,
        textScale: textScale,
        overrides: [
          ...testOverrides(adapter),
          onboardingFlowProvider.overrideWith((ref) {
            final f = FakeOnboardingFlow(ref);
            setup?.call(f);
            return f;
          }),
        ],
      ),
    );
    container = ProviderScope.containerOf(t.element(find.byType(Scaffold)));
    flow = container.read(onboardingFlowProvider) as FakeOnboardingFlow;
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  Finder field(String id) => find.descendant(
    of: find.bySemanticsIdentifier(id),
    matching: find.byType(TextField),
  );

  Future<void> tapId(WidgetTester t, String id) async {
    await t.ensureVisible(find.bySemanticsIdentifier(id));
    await t.pump(const Duration(milliseconds: 300)); // termina a rolagem
    await t.tap(find.bySemanticsIdentifier(id));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  group('cadastro em inglês com fonte 2x não quebra', () {
    final screens = <String, Widget>{
      'dados (ENT08)': ProfileStepScreen(now: DateTime(2026, 11, 21)),
      '@ (ENT11)': const UsernameStepScreen(),
      'interesses (ENT12)': const InterestsStepScreen(),
      'bloqueio (ENT10)': const MinorBlockedScreen(),
    };
    for (final e in screens.entries) {
      testWidgets(e.key, (t) async {
        await show(t, e.value, locale: const Locale('en'), textScale: 2);
        expect(t.takeException(), isNull);
      });
    }
  });

  testWidgets(
    'ENT08: sem nome e sem data mostra os erros no campo e não envia',
    (t) async {
      await show(t, ProfileStepScreen(now: DateTime(2026, 11, 21)));
      await tapId(t, 'onboarding.profile.submit');
      await t.ensureVisible(
        find.bySemanticsIdentifier('onboarding.profile.name'),
      );
      await t.pump();
      expect(find.text(_pt.displayNameLength), findsOneWidget);
      expect(find.text(_pt.birthDateRequired), findsOneWidget);
      expect(flow.calls, isEmpty);
    },
  );

  Future<void> fillProfile(WidgetTester t, {String name = 'Ana Teste'}) async {
    await t.enterText(field('onboarding.profile.name'), name);
    await tapId(t, 'onboarding.profile.birth');
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
  }

  testWidgets('ENT08: envia nome, data escolhida e gênero opcional', (t) async {
    await show(t, ProfileStepScreen(now: DateTime(2026, 11, 21)));
    await fillProfile(t);
    await tapId(t, 'onboarding.profile.gender.nao_binario');
    await tapId(t, 'onboarding.profile.submit');
    expect(flow.calls.single, 'profile:Ana Teste:2001:nao_binario');
  });

  testWidgets('ENT08: nome proibido pelo servidor aparece no campo', (t) async {
    await show(t, ProfileStepScreen(now: DateTime(2026, 11, 21)));
    flow.error = const ApiFailure(
      status: 400,
      code: 'validacao',
      details: {'field': 'displayName', 'reason': 'proibido'},
    );
    await fillProfile(t, name: 'Nome Ruim');
    await tapId(t, 'onboarding.profile.submit');
    await t.ensureVisible(
      find.bySemanticsIdentifier('onboarding.profile.name'),
    );
    await t.pump();
    expect(find.text(_pt.displayNameForbidden), findsOneWidget);
  });

  testWidgets('ENT08: sem conexão mostra o aviso de rede', (t) async {
    await show(t, ProfileStepScreen(now: DateTime(2026, 11, 21)));
    flow.error = const NetworkFailure();
    await fillProfile(t);
    await tapId(t, 'onboarding.profile.submit');
    expect(find.text(_pt.errorNetwork), findsOneWidget);
  });

  testWidgets('ENT11: @ ocupado mostra motivo e sugestões; sugestão libera', (
    t,
  ) async {
    await show(
      t,
      const UsernameStepScreen(debounce: Duration(milliseconds: 10)),
      setup: (f) => f.onCheck = (u) => u == 'ana'
          ? const UsernameCheck(
              available: false,
              reason: 'ocupado',
              suggestions: ['ana.teste2'],
            )
          : const UsernameCheck(available: true),
    );
    await t.enterText(field('onboarding.username.input'), 'ana');
    await t.pump(const Duration(milliseconds: 50));
    await t.pump();
    expect(find.text(_pt.usernameTaken), findsOneWidget);
    final submit = find.descendant(
      of: find.bySemanticsIdentifier('onboarding.username.submit'),
      matching: find.byType(FilledButton),
    );
    expect(t.widget<FilledButton>(submit).onPressed, isNull);
    await tapId(t, 'onboarding.username.suggestion.0');
    await t.pump(const Duration(milliseconds: 50));
    await t.pump();
    expect(find.text(_pt.usernameAvailable), findsOneWidget);
    await tapId(t, 'onboarding.username.submit');
    expect(flow.calls.last, 'set:ana.teste2');
  });

  testWidgets('ENT11: só consulta depois de parar de digitar', (t) async {
    await show(
      t,
      const UsernameStepScreen(debounce: Duration(milliseconds: 300)),
    );
    await t.enterText(field('onboarding.username.input'), 'a');
    await t.pump(const Duration(milliseconds: 100));
    await t.enterText(field('onboarding.username.input'), 'ab');
    await t.pump(const Duration(milliseconds: 100));
    await t.enterText(field('onboarding.username.input'), 'abc');
    await t.pump(const Duration(milliseconds: 400));
    expect(flow.calls.where((c) => c.startsWith('check:')), ['check:abc']);
  });

  testWidgets('ENT12: escolhe, limite de 10, pular envia lista vazia', (
    t,
  ) async {
    await show(t, const InterestsStepScreen());
    await t.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 10; i++) {
      await tapId(t, 'onboarding.interests.i$i');
    }
    expect(find.text(_pt.interestsLimit), findsOneWidget);
    final eleventh = find.descendant(
      of: find.bySemanticsIdentifier('onboarding.interests.i10'),
      matching: find.byType(FilterChip),
    );
    expect(t.widget<FilterChip>(eleventh).onSelected, isNull);
    await tapId(t, 'onboarding.interests.submit');
    expect(flow.calls.last, startsWith('interests:i0,i1'));
    await tapId(t, 'onboarding.interests.skip');
    expect(flow.calls.last, 'interests:');
  });

  testWidgets('ENT12: erro ao carregar mostra "tentar de novo"', (t) async {
    await show(
      t,
      const InterestsStepScreen(),
      setup: (f) => f.error = const NetworkFailure(),
    );
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text(_pt.actionRetry), findsOneWidget);
  });

  testWidgets('ENT10: tela de bloqueio mostra suporte do tenant e protocolo', (
    t,
  ) async {
    await show(t, const MinorBlockedScreen());
    container
        .read(appGateProvider.notifier)
        .set(const GateMinorBlocked('P-1234ABCD'));
    await t.pump();
    expect(find.text(_pt.minorBlockedProtocol('P-1234ABCD')), findsOneWidget);
    final email = container.read(tenantProvider).supportEmail;
    expect(find.text(_pt.minorBlockedReview(email)), findsOneWidget);
  });
}

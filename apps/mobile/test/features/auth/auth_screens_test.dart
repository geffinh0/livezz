import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/auth/auth_api.dart';
import 'package:livezz_mobile/core/auth/session.dart';
import 'package:livezz_mobile/core/errors/app_failure.dart';
import 'package:livezz_mobile/features/auth/application/auth_flow.dart';
import 'package:livezz_mobile/features/auth/presentation/code_screen.dart';
import 'package:livezz_mobile/features/auth/presentation/email_screen.dart';
import 'package:livezz_mobile/features/auth/presentation/google_test_screen.dart';
import 'package:livezz_mobile/features/auth/presentation/phone_screen.dart';
import 'package:livezz_mobile/features/auth/presentation/reset_screen.dart';
import 'package:livezz_mobile/features/auth/presentation/terms_screen.dart';
import 'package:livezz_mobile/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/harness.dart';

/// Fluxo falso: registra chamadas e falha com [error] quando definido.
class FakeAuthFlow extends AuthFlow {
  FakeAuthFlow(super.ref);
  Object? error;
  final calls = <String>[];

  Future<T> _run<T>(String name, T value) async {
    calls.add(name);
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<({int expiresIn, int resendIn})> sendCode({
    required String channel,
    required String destination,
    required String purpose,
  }) => _run('send:$channel:$destination:$purpose', (
    expiresIn: 45,
    resendIn: 30,
  ));

  @override
  Future<void> verifyCode({
    required String destination,
    required String code,
    required String purpose,
    String? password,
  }) => _run('verify:$code', null);

  @override
  Future<({int expiresIn, int resendIn})> signupEmail(
    String email,
    String password,
  ) => _run('signup:$email', (expiresIn: 60, resendIn: 60));

  @override
  Future<void> loginEmail(String email, String password) =>
      _run('login:$email', null);

  @override
  Future<void> google(String idToken) => _run('google:$idToken', null);

  @override
  Future<void> resetPassword(String email, String code, String newPassword) =>
      _run('reset:$email:$code', null);

  @override
  Future<void> acceptTerms(List<PendingTerm> terms) =>
      _run('terms:${terms.length}', null);
}

final _url = Uri.parse('http://p/legal/termos');
final _pt = lookupAppLocalizations(const Locale('pt'));

Map<String, dynamic> _config() => {
  ...sampleConfig(),
  'flags': {
    'loginPhone': true,
    'loginSms': true,
    'loginWhatsapp': false,
    'loginEmail': true,
    'loginGoogle': true,
  },
};

void main() {
  late FakeAuthFlow flow;

  Future<void> show(
    WidgetTester t,
    Widget screen, {
    Locale locale = const Locale('pt'),
    double textScale = 1,
    Session? session,
  }) async {
    final adapter = StubAdapter((o) => jsonBody(200, _config()));
    await t.pumpWidget(
      harness(
        screen,
        locale: locale,
        textScale: textScale,
        overrides: [
          ...testOverrides(adapter),
          authFlowProvider.overrideWith(FakeAuthFlow.new),
        ],
      ),
    );
    final c = ProviderScope.containerOf(t.element(find.byType(Scaffold)));
    flow = c.read(authFlowProvider) as FakeAuthFlow;
    if (session != null) c.read(sessionProvider.notifier).set(session);
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  Finder field(String id) => find.descendant(
    of: find.bySemanticsIdentifier(id),
    matching: find.byType(TextField),
  );

  Future<void> tapId(WidgetTester t, String id) async {
    await t.ensureVisible(find.bySemanticsIdentifier(id));
    await t.tap(find.bySemanticsIdentifier(id));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  const code = CodeArgs(
    destination: '+5511912345678',
    channel: 'sms',
    purpose: 'login',
    expiresIn: 45,
    resendIn: 30,
  );

  final screens = <String, (Widget, Session?)>{
    'telefone': (const PhoneScreen(), null),
    'código': (const CodeScreen(args: code), null),
    'e-mail': (const EmailScreen(signup: true), null),
    'recuperar senha': (const ResetScreen(), null),
    'Google de teste': (const GoogleTestScreen(), null),
    'termos': (
      const TermsScreen(),
      Session(
        userId: 'u1',
        pendingTerms: [PendingTerm(document: 'terms', version: 2, url: _url)],
      ),
    ),
  };

  group('telas de login em inglês com fonte 2x não quebram', () {
    for (final e in screens.entries) {
      testWidgets(e.key, (t) async {
        await show(
          t,
          e.value.$1,
          locale: const Locale('en'),
          textScale: 2,
          session: e.value.$2,
        );
        expect(t.takeException(), isNull);
      });
    }
  });

  testWidgets('ENT04: número incompleto mostra erro no campo, sem chamar o '
      'servidor', (t) async {
    await show(t, const PhoneScreen());
    await t.enterText(field('auth.phone.input'), '1191');
    await tapId(t, 'auth.phone.send');
    expect(find.text(_pt.phoneInvalid), findsOneWidget);
    expect(flow.calls, isEmpty);
  });

  testWidgets('ENT04: sem conexão mostra o aviso de rede', (t) async {
    await show(t, const PhoneScreen());
    flow.error = const NetworkFailure();
    await t.enterText(field('auth.phone.input'), '11912345678');
    await tapId(t, 'auth.phone.send');
    expect(flow.calls.single, 'send:sms:+5511912345678:login');
    expect(find.text(_pt.errorNetwork), findsOneWidget);
  });

  testWidgets('ENT04: tela do código usa a validade e o reenvio do servidor', (
    t,
  ) async {
    await show(t, const CodeScreen(args: code));
    expect(find.textContaining('45'), findsOneWidget);
    expect(find.text(_pt.codeResendIn(30)), findsOneWidget);
    await t.pump(const Duration(seconds: 31));
    expect(find.text(_pt.codeResend), findsOneWidget);
  });

  testWidgets('ENT04: código errado mostra o erro traduzido', (t) async {
    await show(t, const CodeScreen(args: code));
    flow.error = const ApiFailure(status: 400, code: 'codigo_invalido');
    await t.enterText(field('auth.code.input'), '123456');
    await t.pump();
    expect(flow.calls.single, 'verify:123456');
    expect(find.text(_pt.errorCodigoInvalido), findsOneWidget);
  });

  testWidgets('ENT05: e-mail inválido aparece no campo', (t) async {
    await show(t, const EmailScreen(signup: false));
    await t.enterText(field('auth.email.input'), 'sem-arroba');
    await t.enterText(field('auth.password.input'), 'qualquer1');
    await tapId(t, 'auth.email.submit');
    expect(find.text(_pt.emailInvalid), findsOneWidget);
    expect(flow.calls, isEmpty);
  });

  testWidgets('ENT05: credenciais erradas mostram mensagem única', (t) async {
    await show(t, const EmailScreen(signup: false));
    flow.error = const ApiFailure(status: 401, code: 'credenciais_invalidas');
    await t.enterText(field('auth.email.input'), 'ana@teste.local');
    await t.enterText(field('auth.password.input'), 'errada123');
    await tapId(t, 'auth.email.submit');
    expect(find.text(_pt.errorCredenciaisInvalidas), findsOneWidget);
  });

  testWidgets('ENT05: senha fraca no cadastro não chama o servidor', (t) async {
    await show(t, const EmailScreen(signup: true));
    await t.enterText(field('auth.email.input'), 'nova@teste.local');
    await t.enterText(field('auth.password.input'), 'curta');
    await tapId(t, 'auth.email.submit');
    expect(find.text(_pt.passwordWeak), findsOneWidget);
    expect(flow.calls, isEmpty);
  });

  testWidgets('ENT07: pede o código e depois exige senha forte', (t) async {
    await show(t, const ResetScreen());
    await t.enterText(field('auth.reset.email'), 'ana@teste.local');
    await tapId(t, 'auth.reset.submit');
    expect(flow.calls.single, 'send:email:ana@teste.local:reset');
    expect(find.text(_pt.resetCodeSent), findsOneWidget);
    await t.enterText(field('auth.reset.code'), '123456');
    await t.enterText(field('auth.reset.password'), 'fraca');
    await tapId(t, 'auth.reset.submit');
    expect(find.text(_pt.passwordWeak), findsOneWidget);
    expect(flow.calls, hasLength(1));
  });

  testWidgets('ENT07: código errado mostra o erro', (t) async {
    await show(t, const ResetScreen());
    await t.enterText(field('auth.reset.email'), 'ana@teste.local');
    await tapId(t, 'auth.reset.submit');
    flow.error = const ApiFailure(status: 400, code: 'codigo_invalido');
    await t.enterText(field('auth.reset.code'), '000000');
    await t.enterText(field('auth.reset.password'), 'NovaSenha2026');
    await tapId(t, 'auth.reset.submit');
    expect(find.text(_pt.errorCodigoInvalido), findsOneWidget);
  });

  testWidgets('ENT06: conta de teste com falha mostra o erro', (t) async {
    await show(t, const GoogleTestScreen());
    flow.error = const ApiFailure(status: 401, code: 'credenciais_invalidas');
    await tapId(t, 'auth.google.failing');
    expect(flow.calls.single, 'google:mock-google:erro');
    expect(find.text(_pt.errorCredenciaisInvalidas), findsOneWidget);
  });

  testWidgets('ENT16: aceitar só depois de marcar; erro de rede aparece', (
    t,
  ) async {
    await show(
      t,
      const TermsScreen(),
      session: Session(
        userId: 'u1',
        pendingTerms: [PendingTerm(document: 'terms', version: 2, url: _url)],
      ),
    );
    expect(find.text(_pt.termsVersion(2)), findsOneWidget);
    await tapId(t, 'auth.terms.accept');
    expect(flow.calls, isEmpty);
    await tapId(t, 'auth.terms.agree');
    flow.error = const NetworkFailure();
    await tapId(t, 'auth.terms.accept');
    expect(flow.calls.single, 'terms:1');
    expect(find.text(_pt.errorNetwork), findsOneWidget);
  });
}

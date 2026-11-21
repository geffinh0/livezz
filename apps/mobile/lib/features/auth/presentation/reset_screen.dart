import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_flow.dart';
import '../domain/password_rules.dart';
import 'auth_widgets.dart';
import 'password_checklist.dart';

/// ENT07: código por e-mail → nova senha → derruba as sessões (RN-04).
class ResetScreen extends ConsumerStatefulWidget {
  const ResetScreen({super.key});
  @override
  ConsumerState<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends ConsumerState<ResetScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on Object catch (e) {
      setState(() => _error = authErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final flow = ref.read(authFlowProvider);
    return AuthScaffold(
      id: 'auth.reset',
      title: l.forgotPassword,
      children: [
        Text(_codeSent ? l.resetCodeSent : l.resetIntro),
        const SizedBox(height: AppSpace.lg),
        TestId(
          'auth.reset.email',
          child: AppTextField(
            label: l.emailLabel,
            controller: _email,
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            showCounter: false,
            maxLength: 254,
            validator: (v) => v.trim().isEmpty || looksLikeEmail(v.trim())
                ? null
                : l.emailInvalid,
          ),
        ),
        if (_codeSent) ...[
          const SizedBox(height: AppSpace.md),
          TestId(
            'auth.reset.code',
            child: AppTextField(
              label: l.codeLabel,
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              showCounter: false,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              semanticsHint: l.codeSemantics,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TestId(
            'auth.reset.password',
            child: AppTextField(
              label: l.newPasswordLabel,
              controller: _password,
              password: true,
              showCounter: false,
              maxLength: 128,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
            ),
          ),
          PasswordChecklist(password: _password.text),
        ],
        AuthError(_error),
        const SizedBox(height: AppSpace.xl),
        TestId(
          'auth.reset.submit',
          child: AppButton(
            label: _codeSent ? l.resetSave : l.actionSendCode,
            loading: _busy,
            onPressed: () => _run(() async {
              final email = _email.text.trim();
              if (!looksLikeEmail(email)) {
                setState(() => _error = l.emailInvalid);
                return;
              }
              if (_codeSent && passwordProblems(_password.text).isNotEmpty) {
                setState(() => _error = l.passwordWeak);
                return;
              }
              if (!_codeSent) {
                await flow.sendCode(
                  channel: 'email',
                  destination: email,
                  purpose: 'reset',
                );
                setState(() => _codeSent = true);
                return;
              }
              await flow.resetPassword(email, _code.text, _password.text);
              if (!context.mounted) return;
              AppToast.show(context, l.resetDone);
              context.go(Routes.entryMethod('email'));
            }),
          ),
        ),
      ],
    );
  }
}

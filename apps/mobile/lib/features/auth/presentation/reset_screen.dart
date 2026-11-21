import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_flow.dart';
import '../domain/password_rules.dart';
import 'auth_widgets.dart';

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
          child: TextField(
            controller: _email,
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l.emailLabel),
          ),
        ),
        if (_codeSent) ...[
          const SizedBox(height: AppSpace.md),
          TestId(
            'auth.reset.code',
            child: TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l.codeLabel,
                counterText: '',
              ),
            ),
          ),
          TestId(
            'auth.reset.password',
            child: TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l.newPasswordLabel,
                helperText: l.passwordRuleLength,
              ),
            ),
          ),
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

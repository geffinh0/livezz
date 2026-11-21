import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_flow.dart';
import '../domain/password_rules.dart';
import 'auth_widgets.dart';
import 'code_screen.dart';
import 'password_checklist.dart';

/// ENT05: entrar ou criar conta com e-mail e senha (RN-03).
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({required this.signup, super.key});
  final bool signup;
  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _signup = widget.signup;
  bool _busy = false;
  String? _error;
  String? _emailError;
  Set<PasswordRule> _serverRules = {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!looksLikeEmail(email)) {
      setState(() => _emailError = l.emailInvalid);
      return;
    }
    if (_emailError != null) setState(() => _emailError = null);
    if (_signup && passwordProblems(_password.text).isNotEmpty) {
      setState(() => _error = l.passwordWeak);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _serverRules = {};
    });
    final flow = ref.read(authFlowProvider);
    try {
      if (_signup) {
        final r = await flow.signupEmail(email, _password.text);
        if (!mounted) return;
        unawaited(
          context.push(
            Routes.entryCode,
            extra: CodeArgs(
              destination: email,
              channel: 'email',
              purpose: 'signup',
              expiresIn: r.expiresIn,
              resendIn: r.resendIn,
              password: _password.text,
            ),
          ),
        );
      } else {
        await flow.loginEmail(email, _password.text);
      }
    } on ApiFailure catch (e) {
      setState(() {
        _error = authErrorText(l, e);
        _serverRules = rulesFromServer(e.details['rules']);
      });
    } on Object catch (e) {
      setState(() => _error = authErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      id: 'auth.email',
      title: _signup ? l.actionCreateAccount : l.actionSignIn,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l.actionSignIn)),
            ButtonSegment(value: true, label: Text(l.actionCreateAccount)),
          ],
          selected: {_signup},
          onSelectionChanged: (s) => setState(() {
            _signup = s.first;
            _error = null;
          }),
        ),
        const SizedBox(height: AppSpace.xl),
        TestId(
          'auth.email.input',
          child: AppTextField(
            label: l.emailLabel,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            showCounter: false,
            maxLength: 254,
            error: _emailError,
            validator: (v) => v.trim().isEmpty || looksLikeEmail(v.trim())
                ? null
                : l.emailInvalid,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        TestId(
          'auth.password.input',
          child: AppTextField(
            label: l.passwordLabel,
            controller: _password,
            password: true,
            showCounter: false,
            maxLength: 128,
            autofillHints: [
              _signup ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ),
        if (_signup)
          PasswordChecklist(
            password: _password.text,
            serverRules: _serverRules,
          ),
        AuthError(_error),
        const SizedBox(height: AppSpace.xl),
        TestId(
          'auth.email.submit',
          child: AppButton(
            label: _signup ? l.actionCreateAccount : l.actionSignIn,
            loading: _busy,
            onPressed: _submit,
          ),
        ),
        if (!_signup)
          TestId(
            'auth.email.forgot',
            child: AppButton(
              label: l.forgotPassword,
              variant: AppButtonVariant.text,
              onPressed: () => context.push(Routes.entryReset),
            ),
          ),
      ],
    );
  }
}

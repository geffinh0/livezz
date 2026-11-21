import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_flow.dart';
import '../domain/password_rules.dart';
import 'auth_widgets.dart';

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
  bool _obscure = true;
  String? _error;
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
      setState(() => _error = l.emailInvalid);
      return;
    }
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
        await flow.signupEmail(email, _password.text);
        if (!mounted) return;
        unawaited(
          context.push(
            Routes.entryCode(
              destination: email,
              channel: 'email',
              purpose: 'signup',
            ),
            extra: _password.text,
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
    final problems = {...passwordProblems(_password.text), ..._serverRules};
    String ruleText(PasswordRule r) => switch (r) {
      PasswordRule.minLength => l.passwordRuleLength,
      PasswordRule.letters => l.passwordRuleLetters,
      PasswordRule.numbers => l.passwordRuleNumbers,
      PasswordRule.common => l.passwordRuleCommon,
    };
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
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l.emailLabel),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        TestId(
          'auth.password.input',
          child: TextField(
            controller: _password,
            obscureText: _obscure,
            autofillHints: [
              _signup ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l.passwordLabel,
              suffixIcon: IconButton(
                tooltip: _obscure ? l.passwordShow : l.passwordHide,
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        if (_signup)
          for (final r in PasswordRule.values)
            if (r != PasswordRule.common || problems.contains(r))
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpace.xs),
                child: Text(
                  '${problems.contains(r) ? '✗' : '✓'} ${ruleText(r)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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

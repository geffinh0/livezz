import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_flow.dart';
import '../domain/phone.dart';
import 'auth_widgets.dart';

/// Código de 6 dígitos (ENT04, ENT05): validade e reenvio com contagem
/// regressiva (RN-02). O autopreenchimento do Android entra na Fase 12 (Q-51).
class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({
    required this.destination,
    required this.channel,
    required this.purpose,
    super.key,
    this.password,
  });
  final String destination;
  final String channel;
  final String purpose;

  /// Cadastro por e-mail: a senha digitada antes (só em memória, nunca na URL).
  final String? password;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final _ctrl = TextEditingController();
  Timer? _timer;
  int _resendIn = 60;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown(60);
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _resendIn = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      if (_resendIn == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l = AppLocalizations.of(context);
    if (_ctrl.text.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authFlowProvider)
          .verifyCode(
            destination: widget.destination,
            code: _ctrl.text,
            purpose: widget.purpose,
            password: widget.password,
          );
      // O roteador leva ao próximo passo (termos, cadastro ou Home).
    } on Object catch (e) {
      setState(() => _error = authErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final l = AppLocalizations.of(context);
    try {
      final r = await ref
          .read(authFlowProvider)
          .sendCode(
            channel: widget.channel,
            destination: widget.destination,
            purpose: widget.purpose,
          );
      _startCountdown(r.resendIn);
      setState(() => _error = null);
    } on Object catch (e) {
      setState(() => _error = authErrorText(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final shown = widget.destination.contains('@')
        ? widget.destination
        : maskForDisplay(widget.destination);
    return AuthScaffold(
      id: 'auth.code',
      title: l.codeTitle,
      children: [
        Text(l.codeSentTo(shown)),
        const SizedBox(height: AppSpace.lg),
        TestId(
          'auth.code.input',
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(letterSpacing: 8),
            decoration: InputDecoration(
              labelText: l.codeLabel,
              counterText: '',
            ),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
          ),
        ),
        AuthError(_error),
        const SizedBox(height: AppSpace.xl),
        TestId(
          'auth.code.verify',
          child: AppButton(
            label: l.actionConfirm,
            loading: _busy,
            onPressed: _verify,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        TestId(
          'auth.code.resend',
          child: AppButton(
            label: _resendIn > 0 ? l.codeResendIn(_resendIn) : l.codeResend,
            variant: AppButtonVariant.text,
            onPressed: _resendIn > 0 ? null : _resend,
          ),
        ),
      ],
    );
  }
}

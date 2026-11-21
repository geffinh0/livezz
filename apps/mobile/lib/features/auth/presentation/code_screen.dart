import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_flow.dart';
import '../domain/phone.dart';
import 'auth_widgets.dart';

/// Código de 6 dígitos (ENT04, ENT05): validade e reenvio com contagem
/// regressiva (RN-02). O autopreenchimento do Android entra na Fase 12 (Q-51).
/// O que a tela de código precisa. Vai em `extra` da rota (fica só em
/// memória): destino 🔒 e senha nunca na URL nem no histórico.
class CodeArgs {
  const CodeArgs({
    required this.destination,
    required this.channel,
    required this.purpose,
    required this.expiresIn,
    required this.resendIn,
    this.password,
  });
  final String destination;
  final String channel;
  final String purpose;

  /// Validade e espera para reenviar, como o servidor mandou (RN-02).
  final int expiresIn;
  final int resendIn;

  /// Cadastro por e-mail: a senha digitada antes.
  final String? password;
}

class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({required this.args, super.key});
  final CodeArgs args;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final _ctrl = TextEditingController();
  Timer? _timer;
  late int _expiresIn = widget.args.expiresIn;
  int _resendIn = 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.args.resendIn);
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
            destination: widget.args.destination,
            code: _ctrl.text,
            purpose: widget.args.purpose,
            password: widget.args.password,
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
            channel: widget.args.channel,
            destination: widget.args.destination,
            purpose: widget.args.purpose,
          );
      _startCountdown(r.resendIn);
      setState(() {
        _error = null;
        _expiresIn = r.expiresIn;
      });
    } on Object catch (e) {
      setState(() => _error = authErrorText(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dest = widget.args.destination;
    final shown = dest.contains('@') ? dest : maskForDisplay(dest);
    return AuthScaffold(
      id: 'auth.code',
      title: l.codeTitle,
      children: [
        Text(l.codeSentTo(shown, _expiresIn)),
        const SizedBox(height: AppSpace.lg),
        TestId(
          'auth.code.input',
          child: AppTextField(
            label: l.codeLabel,
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            showCounter: false,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(letterSpacing: 8),
            semanticsHint: l.codeSemantics,
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

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_widgets.dart';
import '../application/onboarding_flow.dart';
import '../data/profile_api.dart';
import 'onboarding_widgets.dart';

/// ENT11: @ com checagem de disponibilidade enquanto digita (o servidor
/// decide formato, reservados e ocupados; RN-05) e sugestões tocáveis.
class UsernameStepScreen extends ConsumerStatefulWidget {
  const UsernameStepScreen({
    super.key,
    this.debounce = const Duration(milliseconds: 400),
  });

  /// Espera depois de parar de digitar antes de consultar.
  final Duration debounce;

  @override
  ConsumerState<UsernameStepScreen> createState() => _UsernameStepScreenState();
}

class _UsernameStepScreenState extends ConsumerState<UsernameStepScreen> {
  final _ctrl = TextEditingController();
  Timer? _timer;
  int _seq = 0;
  bool _checking = false;
  bool _busy = false;
  UsernameCheck? _check;
  String? _checkedFor;
  String? _error;

  /// A consulta falhou (rede/servidor): mostra "tentar de novo".
  bool _checkFailed = false;

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _timer?.cancel();
    setState(() {
      _check = null;
      _error = null;
      _checkFailed = false;
      _checking = v.isNotEmpty;
    });
    if (v.isEmpty) return;
    _timer = Timer(widget.debounce, () => _run(v));
  }

  Future<void> _run(String v) async {
    final seq = ++_seq;
    try {
      final r = await ref.read(onboardingFlowProvider).checkUsername(v);
      if (!mounted || seq != _seq) return; // resposta antiga
      setState(() {
        _check = r;
        _checkedFor = v;
        _checking = false;
      });
    } on Object catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _checking = false;
        _checkFailed = true;
        _error = authErrorText(AppLocalizations.of(context), e);
      });
    }
  }

  void _pick(String s) {
    _ctrl.text = s;
    _ctrl.selection = TextSelection.collapsed(offset: s.length);
    _onChanged(s);
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(onboardingFlowProvider).setUsername(_ctrl.text);
    } on ApiFailure catch (e) {
      if (e.code == 'username_indisponivel') {
        // Alguém pegou no meio do caminho: consulta de novo para mostrar sugestões.
        await _run(_ctrl.text);
      } else {
        setState(() => _error = authErrorText(l, e));
      }
    } on Object catch (e) {
      setState(() => _error = authErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _check;
    final current = c != null && _checkedFor == _ctrl.text;
    final fieldError = !current || c.available
        ? null
        : switch (c.reason) {
            'ocupado' => l.usernameTaken,
            'reservado' => l.usernameReserved,
            _ => l.usernameFormat,
          };
    final status = _checking
        ? l.usernameChecking
        : current && c.available
        ? l.usernameAvailable
        : l.usernameHelper;
    return OnboardingScaffold(
      id: 'onboarding.username',
      title: l.onboardingUsernameTitle,
      step: 2,
      children: [
        TestId(
          'onboarding.username.input',
          child: AppTextField(
            label: l.usernameLabel,
            controller: _ctrl,
            hint: l.usernameHint,
            helper: status,
            error: fieldError,
            maxLength: 20,
            autofillHints: const [AutofillHints.newUsername],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9._]')),
              TextInputFormatter.withFunction(
                (_, v) => v.copyWith(text: v.text.toLowerCase()),
              ),
            ],
            onChanged: _onChanged,
          ),
        ),
        if (current && !c.available && c.suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            l.usernameSuggestions,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final (i, s) in c.suggestions.indexed)
                TestId(
                  'onboarding.username.suggestion.$i',
                  child: ActionChip(
                    label: Text(l.usernameHandle(s)),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onPressed: () => _pick(s),
                  ),
                ),
            ],
          ),
        ],
        AuthError(_error),
        if (_checkFailed)
          TestId(
            'onboarding.username.retry',
            child: AppButton(
              label: l.actionRetry,
              variant: AppButtonVariant.text,
              onPressed: () => _onChanged(_ctrl.text),
            ),
          ),
        const SizedBox(height: AppSpace.xl),
        TestId(
          'onboarding.username.submit',
          child: AppButton(
            label: l.actionContinue,
            loading: _busy,
            onPressed: current && c.available ? _submit : null,
          ),
        ),
      ],
    );
  }
}

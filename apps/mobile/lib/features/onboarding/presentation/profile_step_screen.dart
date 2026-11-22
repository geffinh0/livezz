import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_date_field.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_widgets.dart';
import '../application/onboarding_flow.dart';
import 'onboarding_widgets.dart';

/// ENT08: nome de exibição, data de nascimento (não muda depois) e gênero
/// opcional e privado (Q-59). Quem decide a idade é o servidor (RN-01).
class ProfileStepScreen extends ConsumerStatefulWidget {
  const ProfileStepScreen({super.key, this.now});

  /// Só para testes (data de hoje).
  final DateTime? now;

  @override
  ConsumerState<ProfileStepScreen> createState() => _ProfileStepScreenState();
}

class _ProfileStepScreenState extends ConsumerState<ProfileStepScreen> {
  static const genders = [
    'mulher',
    'homem',
    'nao_binario',
    'prefiro_nao_dizer',
  ];

  final _name = TextEditingController();
  DateTime? _birth;
  String? _gender;
  bool _busy = false;
  String? _nameError;
  String? _birthError;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  // Só "vazio" aqui: tamanho e palavras proibidas são regras do servidor
  // (RN-05), que responde no próprio campo.
  String? _checkName(AppLocalizations l, String v) =>
      v.trim().isEmpty ? l.displayNameLength : null;

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final nameError = _checkName(l, _name.text);
    setState(() {
      _nameError = nameError;
      _birthError = _birth == null ? l.birthDateRequired : null;
      _error = null;
    });
    if (nameError != null || _birth == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(onboardingFlowProvider)
          .saveProfile(
            displayName: _name.text,
            birthDate: _birth!,
            gender: _gender,
          );
      // O roteador segue para o próximo passo (ou ENT10, se menor).
    } on ApiFailure catch (e) {
      if (!mounted) return;
      final field = e.details['field'];
      setState(() {
        if (field == 'displayName') {
          _nameError = e.details['reason'] == 'proibido'
              ? l.displayNameForbidden
              : l.displayNameLength;
        } else if (field == 'birthDate') {
          _birthError = l.birthDateInvalid;
        } else {
          _error = authErrorText(l, e);
        }
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = widget.now ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String genderText(String g) => switch (g) {
      'mulher' => l.genderWoman,
      'homem' => l.genderMan,
      'nao_binario' => l.genderNonBinary,
      _ => l.genderPreferNot,
    };
    return OnboardingScaffold(
      id: 'onboarding.profile',
      title: l.onboardingProfileTitle,
      step: 1,
      children: [
        TestId(
          'onboarding.profile.name',
          child: AppTextField(
            label: l.displayNameLabel,
            controller: _name,
            helper: l.displayNameHelper,
            error: _nameError,
            maxLength: 30,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
        ),
        const SizedBox(height: AppSpace.md),
        TestId(
          'onboarding.profile.birth',
          child: AppDateField(
            label: l.birthDateLabel,
            value: _birth,
            helper: l.birthDateHelper,
            error: _birthError,
            firstDate: DateTime(today.year - 120, today.month, today.day),
            lastDate: today,
            // Abre perto da idade mínima (RN-01), sem sugerir uma data.
            initialDate: DateTime(today.year - 18, today.month, today.day),
            onChanged: (d) => setState(() {
              _birth = d;
              _birthError = null;
            }),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Semantics(
          header: true,
          child: Text(
            l.genderLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Text(l.genderPrivacy, style: Theme.of(context).textTheme.bodySmall),
        RadioGroup<String>(
          groupValue: _gender,
          onChanged: (v) => setState(() => _gender = v),
          // Grupo com nome: o leitor diz "Gênero (opcional)" junto das opções.
          child: Semantics(
            container: true,
            label: l.genderLabel,
            explicitChildNodes: true,
            child: Column(
              children: [
                for (final g in genders)
                  TestId(
                    'onboarding.profile.gender.$g',
                    child: RadioListTile<String>(
                      value: g,
                      title: Text(genderText(g)),
                      toggleable: true,
                      contentPadding: EdgeInsetsDirectional.zero,
                    ),
                  ),
              ],
            ),
          ),
        ),
        AuthError(_error),
        const SizedBox(height: AppSpace.xl),
        TestId(
          'onboarding.profile.submit',
          child: AppButton(
            label: l.actionContinue,
            loading: _busy,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

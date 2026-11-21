import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/password_rules.dart';

/// Regras de senha (RN-03) com ícone + cor + texto (nunca só cor) e rótulo
/// claro para o leitor de tela. Usada no cadastro e na recuperação de senha.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({
    required this.password,
    this.serverRules = const {},
    super.key,
  });
  final String password;
  final Set<PasswordRule> serverRules;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ok = dark
        ? AppStatusColors.successDark
        : AppStatusColors.successLight;
    final bad = dark ? AppStatusColors.dangerDark : AppStatusColors.dangerLight;
    final problems = {...passwordProblems(password), ...serverRules};
    String text(PasswordRule r) => switch (r) {
      PasswordRule.minLength => l.passwordRuleLength,
      PasswordRule.letters => l.passwordRuleLetters,
      PasswordRule.numbers => l.passwordRuleNumbers,
      PasswordRule.common => l.passwordRuleCommon,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in PasswordRule.values)
          if (r != PasswordRule.common || problems.contains(r))
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpace.xs),
                child: Row(
                  children: [
                    Icon(
                      problems.contains(r)
                          ? Symbols.cancel
                          : Symbols.check_circle,
                      size: 18,
                      color: problems.contains(r) ? bad : ok,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Semantics(
                        label: problems.contains(r) ? l.ruleNotMet : l.ruleMet,
                        child: Text(
                          text(r),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

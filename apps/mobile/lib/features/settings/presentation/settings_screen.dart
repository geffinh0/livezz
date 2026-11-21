import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/i18n/locales.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_widgets.dart';
import '../../onboarding/application/onboarding_flow.dart';

/// Configurações mínimas (plano 1c): Idioma (CFG14). As demais (CFG01–CFG13)
/// entram nas próximas fases.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _error;

  Future<void> _change(Locale locale) async {
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      await ref.read(onboardingFlowProvider).changeLanguage(locale);
    } on Object catch (e) {
      // A troca local já valeu; só o servidor não soube (tenta de novo depois).
      if (mounted) setState(() => _error = authErrorText(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(localeProvider).languageCode;
    final tenant = ref.watch(tenantProvider);
    String name(String code) =>
        code == 'en' ? l.languageEnglish : l.languagePortuguese;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: TestId(
        'settings',
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.sm,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l.settingsLanguage,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            RadioGroup<String>(
              groupValue: current,
              onChanged: (code) {
                if (code != null) _change(Locale(code));
              },
              child: Column(
                children: [
                  for (final tag in tenant.supportedLocales)
                    TestId(
                      'settings.language.${localeFromTag(tag).languageCode}',
                      child: RadioListTile<String>(
                        value: localeFromTag(tag).languageCode,
                        title: Text(name(localeFromTag(tag).languageCode)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
              ),
              child: AuthError(_error),
            ),
          ],
        ),
      ),
    );
  }
}

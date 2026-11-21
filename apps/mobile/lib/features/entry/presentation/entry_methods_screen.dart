import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/config/application/config_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Escolha do método de entrada (ENT03). Métodos ativos vêm das flags.
class EntryMethodsScreen extends ConsumerWidget {
  const EntryMethodsScreen({required this.signup, super.key});

  final bool signup;

  static const methods = [
    ('phone', 'loginPhone', Symbols.smartphone),
    ('email', 'loginEmail', Symbols.mail),
    ('google', 'loginGoogle', Symbols.account_circle),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final config = ref.watch(configControllerProvider).value;
    final active = [
      for (final m in methods)
        if (config?.isEnabled(m.$2) ?? false) m,
    ];
    String label(String method) => switch (method) {
      'phone' => l.methodPhone,
      'email' => l.methodEmail,
      _ => l.methodGoogle,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(signup ? l.actionCreateAccount : l.actionSignIn),
      ),
      body: SafeArea(
        child: TestId(
          'entry.methods',
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.xl),
            children: [
              Semantics(
                header: true,
                child: Text(
                  l.methodsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              if (active.isEmpty)
                TestId(
                  'entry.methods.none',
                  child: SizedBox(
                    height: 200,
                    child: StateView.empty(
                      key: const ValueKey('entry.methods.none'),
                      title: l.methodsNoneTitle,
                      message: l.methodsNoneBody,
                    ),
                  ),
                ),
              for (final m in active) ...[
                TestId(
                  'entry.method.${m.$1}',
                  child: AppButton(
                    label: label(m.$1),
                    icon: m.$3,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(Routes.entryMethod(m.$1)),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
              ],
              const SizedBox(height: AppSpace.xl),
              TestId(
                'entry.adultsOnly',
                child: Row(
                  children: [
                    const Icon(Symbols.eighteen_up_rating),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: Text(l.adultsOnlyNotice)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(l.legalAgreementIntro),
              Wrap(
                spacing: AppSpace.sm,
                children: [
                  TestId(
                    'entry.legal.terms',
                    child: AppButton(
                      label: l.legalTerms,
                      variant: AppButtonVariant.text,
                      onPressed: () => context.push(Routes.legal('terms')),
                    ),
                  ),
                  TestId(
                    'entry.legal.privacy',
                    child: AppButton(
                      label: l.legalPrivacy,
                      variant: AppButtonVariant.text,
                      onPressed: () => context.push(Routes.legal('privacy')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

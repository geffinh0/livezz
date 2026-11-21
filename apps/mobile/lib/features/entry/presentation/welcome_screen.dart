import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/error_messages.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/entry_providers.dart';

/// Boas-vindas (ENT02), visual simples e limpo (Q-45).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final tenant = ref.watch(tenantProvider);
    return Scaffold(
      body: SafeArea(
        child: TestId(
          'entry.welcome',
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: box.maxHeight - AppSpace.xl * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: AppSpace.xxl),
                    Column(
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            tenant.appName,
                            style: t.displaySmall?.copyWith(
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        Text(
                          l.welcomeTagline,
                          style: t.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (ref.watch(sessionEndNoticeProvider)
                            case final code?)
                          TestId(
                            'entry.sessionNotice',
                            child: Semantics(
                              liveRegion: true,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpace.lg),
                                  child: Text(errorMessageFor(l, code)),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpace.xxl),
                        TestId(
                          'entry.welcome.signup',
                          child: AppButton(
                            label: l.actionCreateAccount,
                            onPressed: () => context.push(Routes.entrySignup),
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        TestId(
                          'entry.welcome.login',
                          child: AppButton(
                            label: l.actionSignIn,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => context.push(Routes.entry),
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        TestId(
                          'entry.welcome.explore',
                          child: AppButton(
                            label: l.actionExploreAsVisitor,
                            variant: AppButtonVariant.text,
                            onPressed: () => ref
                                .read(visitorModeProvider.notifier)
                                .set(on: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

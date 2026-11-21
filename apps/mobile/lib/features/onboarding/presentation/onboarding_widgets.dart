import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Esqueleto do cadastro inicial: título, "Passo x de 3", conteúdo rolável e
/// "Sair" (a pessoa nunca fica presa no cadastro). Sem voltar: o roteador
/// decide o passo pelo que o servidor diz que falta.
class OnboardingScaffold extends ConsumerWidget {
  const OnboardingScaffold({
    required this.id,
    required this.title,
    required this.step,
    required this.children,
    super.key,
  });
  final String id;
  final String title;
  final int step;
  final List<Widget> children;

  static const totalSteps = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title),
          actions: [
            TestId(
              '$id.signout',
              child: AppButton(
                label: l.actionSignOut,
                variant: AppButtonVariant.text,
                onPressed: () => ref.read(sessionProvider.notifier).signOut(),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: TestId(
            id,
            child: ListView(
              padding: const EdgeInsetsDirectional.all(AppSpace.xl),
              children: [
                Semantics(
                  label: l.onboardingStepOf(step, totalSteps),
                  excludeSemantics: true,
                  child: LinearProgressIndicator(value: step / totalSteps),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  l.onboardingStepOf(step, totalSteps),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpace.lg),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

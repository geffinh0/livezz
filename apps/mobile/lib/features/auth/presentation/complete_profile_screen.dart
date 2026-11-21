import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Conta nova sem dados iniciais. O cadastro (ENT08: nome, nascimento, 18+)
/// chega no plano 1c (Q-52).
class CompleteProfileScreen extends ConsumerWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.completeProfileTitle)),
      body: TestId(
        'auth.completeProfile',
        child: Column(
          children: [
            Expanded(
              child: StateView.empty(
                title: l.completeProfileTitle,
                message: l.completeProfileBody,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.xl),
              child: TestId(
                'auth.completeProfile.signout',
                child: AppButton(
                  label: l.actionSignOut,
                  variant: AppButtonVariant.text,
                  onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

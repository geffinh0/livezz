import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/auth/pending_action.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_bottom_sheet.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';

/// ENT17: executa [action] se houver conta; senão guarda a ação e pede login.
/// Depois que a pessoa entra, a ação roda sozinha.
Future<void> requireAccount(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  if (ref.read(sessionProvider) != null) {
    await action();
    return;
  }
  ref.read(pendingActionProvider.notifier).hold(PendingAction(action));
  final l = AppLocalizations.of(context);
  await AppBottomSheet.show<void>(
    context,
    title: l.accountRequiredTitle,
    builder: (ctx) => TestId(
      'entry.accountRequired',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Symbols.lock_open),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(l.accountRequiredBody)),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          TestId(
            'entry.accountRequired.signup',
            child: AppButton(
              label: l.actionCreateAccount,
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push(Routes.entrySignup);
              },
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          TestId(
            'entry.accountRequired.login',
            child: AppButton(
              label: l.actionSignIn,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push(Routes.entry);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

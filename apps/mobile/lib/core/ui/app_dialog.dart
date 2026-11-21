import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import 'app_button.dart';

/// Diálogo de confirmação único. Ação destrutiva sempre destacada.
abstract final class AppDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    bool destructive = false,
  }) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton(
            key: const ValueKey('dialog.cancel'),
            label: l.actionCancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            key: const ValueKey('dialog.confirm'),
            label: confirmLabel ?? l.actionConfirm,
            variant: destructive
                ? AppButtonVariant.danger
                : AppButtonVariant.primary,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

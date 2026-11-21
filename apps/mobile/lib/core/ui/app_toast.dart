import 'package:material_ui/material_ui.dart';

/// Aviso curto (feedback de ação, ganho de XP etc.).
abstract final class AppToast {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

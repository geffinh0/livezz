import 'package:material_ui/material_ui.dart';

import '../../../core/ui/state_views.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Método de entrada ainda não implementado (chega no plano 1b, ENT04–ENT07).
class MethodPlaceholderScreen extends StatelessWidget {
  const MethodPlaceholderScreen({required this.method, super.key});
  final String method;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: TestId(
        'entry.method.$method.soon',
        child: StateView.empty(
          title: l.comingSoonTitle,
          message: l.comingSoonBody,
        ),
      ),
    );
  }
}

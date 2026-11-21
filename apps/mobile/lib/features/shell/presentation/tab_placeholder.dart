import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/auth/session.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'home_shell.dart';

/// Conteúdo provisório das abas: o de verdade chega nas fases seguintes
/// (Descobrir/Seguindo na Fase 2, Ao vivo na 3, Mensagens na 6, Perfil na 2).
class TabPlaceholder extends ConsumerWidget {
  const TabPlaceholder({required this.tab, super.key});
  final HomeTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final visitor = ref.watch(sessionProvider) == null;
    final Widget body;
    if (tab == HomeTab.following && visitor) {
      // Q-49: convite, sem abrir o pedido de login.
      body = StateView.empty(
        title: l.followingVisitorTitle,
        message: l.followingVisitorBody,
        actionLabel: l.actionSignIn,
        onAction: () => context.push(Routes.entry),
      );
    } else {
      body = StateView.empty(
        title: l.comingSoonTitle,
        message: l.comingSoonBody,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tab.label(l))),
      body: TestId('tab.${tab.name}', child: body),
    );
  }
}

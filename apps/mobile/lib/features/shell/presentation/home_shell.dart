import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/auth/session.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../entry/presentation/account_required_sheet.dart';

/// Abas da navegação principal (NAV01). Ordem = ordem dos ramos do roteador.
enum HomeTab {
  discover(Routes.discover, Symbols.explore, requiresAccount: false),
  following(Routes.following, Symbols.group, requiresAccount: false),
  live(Routes.live, Symbols.videocam, requiresAccount: true),
  messages(Routes.messages, Symbols.chat, requiresAccount: true),
  profile(Routes.profile, Symbols.person, requiresAccount: true);

  const HomeTab(this.path, this.icon, {required this.requiresAccount});
  final String path;
  final IconData icon;
  final bool requiresAccount;

  String label(AppLocalizations l) => switch (this) {
    HomeTab.discover => l.tabDiscover,
    HomeTab.following => l.tabFollowing,
    HomeTab.live => l.tabLive,
    HomeTab.messages => l.tabMessages,
    HomeTab.profile => l.tabProfile,
  };
}

/// Mensagens não lidas: evento `unread.updated` `{ messages, notifications }`
/// do tempo real (só chega com sessão). Sem sessão: 0.
class UnreadMessagesController extends Notifier<int> {
  @override
  int build() {
    if (ref.watch(sessionProvider) == null) return 0;
    final sub = ref.watch(realtimeClientProvider).on('unread.updated').listen((
      e,
    ) {
      final n = e.data['messages'];
      if (n is int && n >= 0) state = n;
    });
    ref.onDispose(sub.cancel);
    return 0;
  }
}

final unreadMessagesProvider = NotifierProvider<UnreadMessagesController, int>(
  UnreadMessagesController.new,
);

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  Timer? _exitWindow; // aberto após o 1º voltar em Descobrir
  static const _exitWindowDuration = Duration(seconds: 2);

  @override
  void dispose() {
    _exitWindow?.cancel();
    super.dispose();
  }

  void _select(int index) {
    final tab = HomeTab.values[index];
    final shell = widget.shell;
    void go() =>
        shell.goBranch(index, initialLocation: index == shell.currentIndex);
    if (tab.requiresAccount && ref.read(sessionProvider) == null) {
      requireAccount(context, ref, () async => go());
      return;
    }
    go();
  }

  /// Voltar (Q-48): outra aba → Descobrir; em Descobrir, toque duplo para sair.
  void _onBack() {
    if (widget.shell.currentIndex != HomeTab.discover.index) {
      widget.shell.goBranch(HomeTab.discover.index);
      return;
    }
    if (_exitWindow?.isActive ?? false) {
      SystemNavigator.pop();
      return;
    }
    _exitWindow = Timer(_exitWindowDuration, () {});
    AppToast.show(context, AppLocalizations.of(context).pressBackAgainToExit);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final unread = ref.watch(unreadMessagesProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: widget.shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.shell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final tab in HomeTab.values)
              NavigationDestination(
                icon: TestId(
                  'nav.${tab.name}',
                  child: tab == HomeTab.messages && unread > 0
                      ? Semantics(
                          label: l.unreadMessages(unread),
                          child: Badge.count(
                            count: unread,
                            child: Icon(tab.icon),
                          ),
                        )
                      : Icon(
                          tab.icon,
                          size: tab == HomeTab.live ? 32 : null,
                          color: tab == HomeTab.live
                              ? Theme.of(context).colorScheme.tertiary
                              : null,
                        ),
                ),
                label: tab.label(l),
              ),
          ],
        ),
      ),
    );
  }
}

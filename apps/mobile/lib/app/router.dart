import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/pending_action.dart';
import '../core/auth/session.dart';
import '../features/auth/presentation/code_screen.dart';
import '../features/auth/presentation/complete_profile_screen.dart';
import '../features/auth/presentation/email_screen.dart';
import '../features/auth/presentation/google_test_screen.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/auth/presentation/reset_screen.dart';
import '../features/auth/presentation/terms_screen.dart';
import '../features/dev_showcase/presentation/showcase_screen.dart';
import '../features/entry/application/entry_providers.dart';
import '../features/entry/domain/entry_decision.dart';
import '../features/entry/presentation/entry_methods_screen.dart';
import '../features/entry/presentation/gate_screen.dart';
import '../features/entry/presentation/legal_screen.dart';
import '../features/entry/presentation/welcome_screen.dart';
import '../features/shell/presentation/home_shell.dart';
import '../features/shell/presentation/tab_placeholder.dart';
import 'routes.dart';
import 'start_screen.dart';

const _gates = {
  EntryDestination.updateRequired,
  EntryDestination.maintenance,
  EntryDestination.regionBlocked,
};

bool _isEntryFlow(String path) =>
    path == Routes.welcome ||
    path.startsWith(Routes.entry) ||
    path.startsWith('/legal/');

bool _isLoginFlow(String path) =>
    path == Routes.welcome || path.startsWith(Routes.entry);

/// Para onde redirecionar dado o destino decidido (ENT01). Puro e testável.
String? redirectFor(EntryDestination dest, String path) {
  if (kDebugMode && path == Routes.devShowcase) return null;
  if (_gates.contains(dest)) return path == Routes.gate ? null : Routes.gate;
  switch (dest) {
    case EntryDestination.splash:
    case EntryDestination.error:
      return path == Routes.start ? null : Routes.start;
    case EntryDestination.welcome:
      return _isEntryFlow(path) ? null : Routes.welcome;
    case EntryDestination.acceptTerms:
      return path == Routes.terms || path.startsWith('/legal/')
          ? null
          : Routes.terms;
    case EntryDestination.completeProfile:
      return path == Routes.completeProfile ? null : Routes.completeProfile;
    case EntryDestination.home:
      const outside = {
        Routes.start,
        Routes.gate,
        Routes.terms,
        Routes.completeProfile,
      };
      return outside.contains(path) || _isLoginFlow(path)
          ? Routes.discover
          : null;
    default:
      return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<EntryDestination>(
    ref.read(entryDestinationProvider),
  );
  ref
    ..listen(entryDestinationProvider, (_, next) => refresh.value = next)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(refresh.value, state.uri.path),
    routes: [
      GoRoute(path: Routes.start, builder: (c, s) => const StartScreen()),
      GoRoute(path: Routes.gate, builder: (c, s) => const GateScreen()),
      GoRoute(path: Routes.welcome, builder: (c, s) => const WelcomeScreen()),
      GoRoute(
        path: Routes.entry,
        builder: (c, s) => EntryMethodsScreen(
          signup: s.uri.queryParameters['mode'] == 'signup',
        ),
        routes: [
          GoRoute(path: 'method/phone', builder: (c, s) => const PhoneScreen()),
          GoRoute(
            path: 'method/email',
            builder: (c, s) =>
                EmailScreen(signup: s.uri.queryParameters['mode'] == 'signup'),
          ),
          GoRoute(
            path: 'method/google',
            builder: (c, s) => const GoogleTestScreen(),
          ),
          GoRoute(
            path: 'code',
            builder: (c, s) => CodeScreen(
              destination: s.uri.queryParameters['dest'] ?? '',
              channel: s.uri.queryParameters['channel'] ?? 'sms',
              purpose: s.uri.queryParameters['purpose'] ?? 'login',
            ),
          ),
          GoRoute(path: 'reset', builder: (c, s) => const ResetScreen()),
        ],
      ),
      GoRoute(path: Routes.terms, builder: (c, s) => const TermsScreen()),
      GoRoute(
        path: Routes.completeProfile,
        builder: (c, s) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/legal/:doc',
        builder: (c, s) => LegalScreen(doc: s.pathParameters['doc']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => HomeShell(shell: shell),
        branches: [
          for (final tab in HomeTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  builder: (c, s) => TabPlaceholder(tab: tab),
                ),
              ],
            ),
        ],
      ),
      if (kDebugMode)
        GoRoute(
          path: Routes.devShowcase,
          builder: (c, s) => const ShowcaseScreen(),
        ),
    ],
  );
  // ENT19: sessão expirada/encerrada → depois de entrar de novo, volta para
  // onde a pessoa estava (mesmo mecanismo do ENT17).
  ref.listen(sessionProvider, (prev, next) {
    if (prev == null || next != null) return;
    // Saiu por vontade própria: não precisa voltar a lugar nenhum.
    if (ref.read(sessionEndNoticeProvider) == null) return;
    final last = router.routerDelegate.currentConfiguration.uri.toString();
    if (!last.startsWith('/discover') &&
        !last.startsWith('/following') &&
        !last.startsWith('/live') &&
        !last.startsWith('/messages') &&
        !last.startsWith('/profile')) {
      return;
    }
    ref
        .read(pendingActionProvider.notifier)
        .hold(PendingAction(() async => router.go(last)));
  });
  ref.onDispose(router.dispose);
  return router;
});

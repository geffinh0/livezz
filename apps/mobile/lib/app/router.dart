import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dev_showcase/presentation/showcase_screen.dart';
import '../features/entry/application/entry_providers.dart';
import '../features/entry/domain/entry_decision.dart';
import '../features/entry/presentation/entry_methods_screen.dart';
import '../features/entry/presentation/gate_screen.dart';
import '../features/entry/presentation/legal_screen.dart';
import '../features/entry/presentation/method_placeholder_screen.dart';
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
    case EntryDestination.home:
      const outside = {Routes.start, Routes.gate, Routes.welcome};
      return outside.contains(path) ? Routes.discover : null;
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
          GoRoute(
            path: 'method/:method',
            builder: (c, s) =>
                MethodPlaceholderScreen(method: s.pathParameters['method']!),
          ),
        ],
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
  ref.onDispose(router.dispose);
  return router;
});

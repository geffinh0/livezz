import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/pending_action.dart';
import '../core/auth/session.dart';
import '../features/auth/presentation/code_screen.dart';
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
import '../features/entry/presentation/minor_blocked_screen.dart';
import '../features/entry/presentation/welcome_screen.dart';
import '../features/onboarding/presentation/interests_step_screen.dart';
import '../features/onboarding/presentation/profile_step_screen.dart';
import '../features/onboarding/presentation/username_step_screen.dart';
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
    case EntryDestination.onboardingProfile:
      return path == Routes.onboardingProfile ? null : Routes.onboardingProfile;
    case EntryDestination.onboardingUsername:
      return path == Routes.onboardingUsername
          ? null
          : Routes.onboardingUsername;
    case EntryDestination.onboardingInterests:
      return path == Routes.onboardingInterests
          ? null
          : Routes.onboardingInterests;
    case EntryDestination.minorBlocked:
      // ENT10: nada além da tela de bloqueio.
      return path == Routes.minorBlocked ? null : Routes.minorBlocked;
    case EntryDestination.home:
      const outside = {
        Routes.start,
        Routes.gate,
        Routes.terms,
        Routes.minorBlocked,
      };
      return outside.contains(path) ||
              _isLoginFlow(path) ||
              path.startsWith('/onboarding/')
          ? Routes.discover
          : null;
    case EntryDestination.visitorHome:
      // Visitante: pode abrir as telas de entrada (ENT17); pendências não se aplicam.
      const blocked = {
        Routes.start,
        Routes.gate,
        Routes.welcome,
        Routes.terms,
        Routes.minorBlocked,
      };
      return blocked.contains(path) || path.startsWith('/onboarding/')
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
            // Sem os dados em memória (ex.: recarregou a página): volta à escolha.
            redirect: (c, s) => s.extra is CodeArgs ? null : Routes.entry,
            builder: (c, s) => CodeScreen(args: s.extra! as CodeArgs),
          ),
          GoRoute(path: 'reset', builder: (c, s) => const ResetScreen()),
        ],
      ),
      GoRoute(path: Routes.terms, builder: (c, s) => const TermsScreen()),
      GoRoute(
        path: Routes.onboardingProfile,
        builder: (c, s) => const ProfileStepScreen(),
      ),
      GoRoute(
        path: Routes.onboardingUsername,
        builder: (c, s) => const UsernameStepScreen(),
      ),
      GoRoute(
        path: Routes.onboardingInterests,
        builder: (c, s) => const InterestsStepScreen(),
      ),
      GoRoute(
        path: Routes.minorBlocked,
        builder: (c, s) => const MinorBlockedScreen(),
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
  // onde a pessoa estava (sem trocar uma ação ENT17 já guardada).
  ref.listen(sessionProvider, (prev, next) {
    if (prev == null || next != null) return;
    // Saiu por vontade própria: não precisa voltar a lugar nenhum.
    if (ref.read(sessionEndNoticeProvider) == null) return;
    final last = router.routerDelegate.currentConfiguration.uri.toString();
    final inShell = HomeTab.values.any((t) => last.startsWith(t.path));
    if (!inShell) return;
    ref
        .read(pendingActionProvider.notifier)
        .hold(PendingAction(() async => router.go(last)), keepExisting: true);
  });

  // ENT17: a ação pendente roda quando o destino vira a Home (depois de
  // termos e cadastro), no quadro seguinte ao redirecionamento.
  ref.listen(entryDestinationProvider, (prev, next) {
    if (next != EntryDestination.home || prev == EntryDestination.home) return;
    final action = ref.read(pendingActionProvider.notifier).take();
    if (action == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      action.run().catchError((Object e) {
        developer.log('ação pendente falhou: $e', name: 'auth');
      });
    });
  });
  ref.onDispose(router.dispose);
  return router;
});

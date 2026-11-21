import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/dev_showcase/presentation/showcase_screen.dart';
import 'routes.dart';
import 'start_screen.dart';

/// Rotas do app. A vitrine só existe em debug (fora do release).
GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(
      path: Routes.start,
      builder: (context, state) => const StartScreen(),
    ),
    if (kDebugMode)
      GoRoute(
        path: Routes.devShowcase,
        builder: (context, state) => const ShowcaseScreen(),
      ),
  ],
);

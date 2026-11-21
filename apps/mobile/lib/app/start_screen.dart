import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/application/config_controller.dart';
import '../core/theme/tokens.dart';
import '../core/ui/state_views.dart';
import '../core/ui/test_id.dart';
import 'providers.dart';

/// Splash (ENT01): marca do tenant enquanto carrega; erro com "tentar de novo"
/// se a config não vier em até 10 s. O roteador leva ao destino certo.
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configControllerProvider);
    final tenant = ref.watch(tenantProvider);
    final body = switch (config) {
      AsyncError(:final error) => StateView.forFailure(
        context,
        error,
        onRetry: () => ref.read(configControllerProvider.notifier).refresh(),
      ),
      _ => TestId(
        'entry.splash',
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tenant.appName,
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
              ),
              const SizedBox(height: AppSpace.xl),
              const StateView.loading(),
            ],
          ),
        ),
      ),
    };
    return Scaffold(body: SafeArea(child: body));
  }
}

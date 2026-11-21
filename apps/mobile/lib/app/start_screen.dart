import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/application/config_controller.dart';
import '../core/http/app_gate.dart';
import '../core/theme/tokens.dart';
import '../core/ui/state_views.dart';
import '../core/ui/test_id.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'routes.dart';

/// Ponto de entrada da Fase 0: carrega a config e respeita os portões.
/// A decisão completa (Home, Boas-vindas…) é da ENT01 (Fase 1).
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final config = ref.watch(configControllerProvider);
    final gate = ref.watch(appGateProvider);
    void retry() => ref.read(configControllerProvider.notifier).refresh();

    final Widget body = switch ((config, gate)) {
      (_, GateUpdateRequired()) => _Blocking(
        id: 'gate.update',
        icon: Symbols.system_update,
        title: l.updateRequiredTitle,
        message: l.errorAtualizacaoObrigatoria,
      ),
      (AsyncData(:final value), _) when value.maintenance.active => _Blocking(
        id: 'gate.maintenance',
        icon: Symbols.construction,
        title: l.maintenanceTitle,
        message: l.errorManutencao,
      ),
      (_, GateMaintenance()) => _Blocking(
        id: 'gate.maintenance',
        icon: Symbols.construction,
        title: l.maintenanceTitle,
        message: l.errorManutencao,
      ),
      (AsyncError(:final error), _) => StateView.forFailure(
        context,
        error,
        onRetry: retry,
      ),
      (AsyncData(), _) when kDebugMode => const _GoToShowcase(),
      (AsyncData(), _) => const SizedBox.shrink(),
      _ => const StateView.loading(),
    };
    return Scaffold(body: SafeArea(child: body));
  }
}

class _GoToShowcase extends StatelessWidget {
  const _GoToShowcase();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) GoRouter.maybeOf(context)?.go(Routes.devShowcase);
    });
    return const StateView.loading();
  }
}

class _Blocking extends StatelessWidget {
  const _Blocking({
    required this.icon,
    required this.title,
    required this.message,
    required this.id,
  });

  final String id;

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TestId(
      id,
      child: Center(
        key: ValueKey(id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56),
              const SizedBox(height: AppSpace.lg),
              Text(title, style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.sm),
              Text(message, style: t.bodyLarge, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

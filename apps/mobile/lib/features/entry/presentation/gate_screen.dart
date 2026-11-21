import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/config/application/config_controller.dart';
import '../../../core/http/app_gate.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/error_messages.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/entry_providers.dart';
import '../domain/entry_decision.dart';

/// Portões que bloqueiam o app inteiro: atualização obrigatória, manutenção
/// (ENT01, TRV09) e região bloqueada (ENT18). "Tentar de novo" rebusca a config.
class GateScreen extends ConsumerStatefulWidget {
  const GateScreen({super.key});

  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen> {
  static const _gates = {
    EntryDestination.updateRequired,
    EntryDestination.maintenance,
    EntryDestination.regionBlocked,
  };

  // Guarda o último motivo: durante a animação de saída a tela não troca de
  // mensagem.
  EntryDestination _shown = EntryDestination.maintenance;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = ref.watch(entryDestinationProvider);
    if (_gates.contains(now)) _shown = now;
    final dest = _shown;
    final (id, icon, title, message) = switch (dest) {
      EntryDestination.updateRequired => (
        'gate.update',
        Symbols.system_update,
        l.updateRequiredTitle,
        l.errorAtualizacaoObrigatoria,
      ),
      EntryDestination.regionBlocked => (
        'gate.region',
        Symbols.public_off,
        l.regionBlockedTitle,
        errorMessageFor(l, 'regiao_bloqueada'),
      ),
      _ => (
        'gate.maintenance',
        Symbols.construction,
        l.maintenanceTitle,
        l.errorManutencao,
      ),
    };
    void retry() {
      ref.read(appGateProvider.notifier).set(const GateOpen());
      ref.read(configControllerProvider.notifier).refresh();
    }

    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: TestId(
          id,
          child: Center(
            key: ValueKey(id),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 56,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      title,
                      style: t.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    message,
                    style: t.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.xl),
                  TestId(
                    '$id.action',
                    child: AppButton(label: l.actionRetry, onPressed: retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

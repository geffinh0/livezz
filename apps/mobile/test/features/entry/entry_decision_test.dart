import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/features/entry/domain/entry_decision.dart';

void main() {
  EntryDestination d({
    ConfigStatus config = ConfigStatus.ready,
    GateKind gate = GateKind.none,
    bool region = true,
    bool maintenance = false,
    bool? visitor = false,
    bool session = false,
  }) => decideEntry(
    config: config,
    gate: gate,
    regionAllowed: region,
    maintenance: maintenance,
    visitorMode: visitor,
    hasSession: session,
  );

  final table = <String, (EntryDestination, EntryDestination)>{
    'sem sessão e sem escolha → boas-vindas': (d(), EntryDestination.welcome),
    'visitante → home': (d(visitor: true), EntryDestination.home),
    'com sessão → home': (d(session: true), EntryDestination.home),
    'carregando config → splash': (
      d(config: ConfigStatus.loading),
      EntryDestination.splash,
    ),
    'erro na config → erro': (
      d(config: ConfigStatus.error),
      EntryDestination.error,
    ),
    'prefs ainda carregando → splash': (
      d(visitor: null),
      EntryDestination.splash,
    ),
    'região fora (config) → região': (
      d(region: false, session: true),
      EntryDestination.regionBlocked,
    ),
    'região fora (403) mesmo com erro de config → região': (
      d(gate: GateKind.regionBlocked, config: ConfigStatus.error),
      EntryDestination.regionBlocked,
    ),
    'manutenção pela config → manutenção': (
      d(maintenance: true, session: true),
      EntryDestination.maintenance,
    ),
    'manutenção (503) durante carregamento → manutenção': (
      d(gate: GateKind.maintenance, config: ConfigStatus.loading),
      EntryDestination.maintenance,
    ),
    'atualização vence todos os outros': (
      d(gate: GateKind.updateRequired, region: false, maintenance: true),
      EntryDestination.updateRequired,
    ),
    'região vence manutenção': (
      d(region: false, maintenance: true),
      EntryDestination.regionBlocked,
    ),
  };

  for (final e in table.entries) {
    test(e.key, () => expect(e.value.$1, e.value.$2));
  }
}

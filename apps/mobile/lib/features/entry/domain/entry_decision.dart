/// Decisão de para onde o app vai ao abrir e a cada mudança de estado
/// (ENT01, ENT18). Dart puro, testado em tabela.
enum ConfigStatus { loading, error, ready }

enum GateKind { none, updateRequired, maintenance, regionBlocked }

enum EntryDestination {
  splash,
  error,
  updateRequired,
  maintenance,
  regionBlocked,
  welcome,
  home,
}

EntryDestination decideEntry({
  required ConfigStatus config,
  required GateKind gate,
  required bool regionAllowed,
  required bool maintenance,
  required bool? visitorMode,
  required bool hasSession,
}) {
  // Portões têm prioridade: atualização > região > manutenção.
  if (gate == GateKind.updateRequired) return EntryDestination.updateRequired;
  if (gate == GateKind.regionBlocked) return EntryDestination.regionBlocked;
  if (gate == GateKind.maintenance) return EntryDestination.maintenance;
  switch (config) {
    case ConfigStatus.loading:
      return EntryDestination.splash;
    case ConfigStatus.error:
      return EntryDestination.error;
    case ConfigStatus.ready:
      break;
  }
  if (!regionAllowed) return EntryDestination.regionBlocked;
  if (maintenance) return EntryDestination.maintenance;
  if (hasSession) return EntryDestination.home;
  if (visitorMode == null) return EntryDestination.splash;
  return visitorMode ? EntryDestination.home : EntryDestination.welcome;
}

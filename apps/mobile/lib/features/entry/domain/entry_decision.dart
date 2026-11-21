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
  acceptTerms,
  completeProfile,
  home,

  /// Visitante (ENT02): na Home sem sessão; pode abrir as telas de entrada.
  visitorHome,
}

EntryDestination decideEntry({
  required ConfigStatus config,
  required GateKind gate,
  required bool regionAllowed,
  required bool maintenance,
  required bool? visitorMode,
  required bool hasSession,
  bool sessionReady = true,
  bool pendingTerms = false,
  bool needsProfile = false,
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
  if (!sessionReady) return EntryDestination.splash;
  if (hasSession) {
    // ENT16 antes de tudo; depois o cadastro inicial (1c); então a Home.
    if (pendingTerms) return EntryDestination.acceptTerms;
    if (needsProfile) return EntryDestination.completeProfile;
    return EntryDestination.home;
  }
  if (visitorMode == null) return EntryDestination.splash;
  return visitorMode ? EntryDestination.visitorHome : EntryDestination.welcome;
}

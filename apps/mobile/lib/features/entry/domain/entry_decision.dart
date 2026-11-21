import '../../../core/auth/onboarding_step.dart';

export '../../../core/auth/onboarding_step.dart';

/// Decisão de para onde o app vai ao abrir e a cada mudança de estado
/// (ENT01, ENT18). Dart puro, testado em tabela.
enum ConfigStatus { loading, error, ready }

enum GateKind { none, updateRequired, maintenance, regionBlocked, minorBlocked }

enum EntryDestination {
  splash,
  error,
  updateRequired,
  maintenance,
  regionBlocked,
  welcome,
  acceptTerms,

  /// Cadastro inicial (plano 1c), na ordem: dados (ENT08), @ (ENT11), interesses (ENT12).
  onboardingProfile,
  onboardingUsername,
  onboardingInterests,

  /// ENT10: menor de idade; sem acesso ao app.
  minorBlocked,
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
  List<OnboardingStep> pendingSteps = const [],
  bool sessionEnded = false,
}) {
  // Portões têm prioridade: atualização > região > manutenção.
  if (gate == GateKind.updateRequired) return EntryDestination.updateRequired;
  if (gate == GateKind.regionBlocked) return EntryDestination.regionBlocked;
  if (gate == GateKind.maintenance) return EntryDestination.maintenance;
  // ENT10: acima de termos e independente de haver sessão.
  if (gate == GateKind.minorBlocked) return EntryDestination.minorBlocked;
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
    if (pendingSteps.contains(OnboardingStep.profile)) {
      return EntryDestination.onboardingProfile;
    }
    if (pendingSteps.contains(OnboardingStep.username)) {
      return EntryDestination.onboardingUsername;
    }
    if (pendingSteps.contains(OnboardingStep.interests)) {
      return EntryDestination.onboardingInterests;
    }
    return EntryDestination.home;
  }
  // ENT19: a sessão acabou (outro aparelho, expirou): boas-vindas com o
  // aviso, mesmo para quem tinha escolhido explorar sem conta.
  if (sessionEnded) return EntryDestination.welcome;
  if (visitorMode == null) return EntryDestination.splash;
  return visitorMode ? EntryDestination.visitorHome : EntryDestination.welcome;
}

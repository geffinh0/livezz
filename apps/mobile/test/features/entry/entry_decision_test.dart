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
    bool ended = false,
    bool terms = false,
    List<OnboardingStep> steps = const [],
  }) => decideEntry(
    config: config,
    gate: gate,
    regionAllowed: region,
    maintenance: maintenance,
    visitorMode: visitor,
    hasSession: session,
    sessionEnded: ended,
    pendingTerms: terms,
    pendingSteps: steps,
  );

  final table = <String, (EntryDestination, EntryDestination)>{
    'sem sessão e sem escolha → boas-vindas': (d(), EntryDestination.welcome),
    'visitante → home de visitante': (
      d(visitor: true),
      EntryDestination.visitorHome,
    ),
    'com sessão → home': (d(session: true), EntryDestination.home),
    'cadastro: dados primeiro (ENT08)': (
      d(session: true, steps: OnboardingStep.values),
      EntryDestination.onboardingProfile,
    ),
    'cadastro: depois o @ (ENT11)': (
      d(
        session: true,
        steps: [OnboardingStep.username, OnboardingStep.interests],
      ),
      EntryDestination.onboardingUsername,
    ),
    'cadastro: por fim interesses (ENT12)': (
      d(session: true, steps: [OnboardingStep.interests]),
      EntryDestination.onboardingInterests,
    ),
    'termos antes do cadastro (ENT16)': (
      d(session: true, terms: true, steps: OnboardingStep.values),
      EntryDestination.acceptTerms,
    ),
    'menor bloqueado vence termos e sessão (ENT10)': (
      d(gate: GateKind.minorBlocked, session: true, terms: true),
      EntryDestination.minorBlocked,
    ),
    'menor bloqueado mesmo sem sessão (aparelho marcado)': (
      d(gate: GateKind.minorBlocked, visitor: true),
      EntryDestination.minorBlocked,
    ),
    'sessão caiu de quem explorava sem conta → boas-vindas com aviso (ENT19)': (
      d(visitor: true, ended: true),
      EntryDestination.welcome,
    ),
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
    'sessão ainda restaurando → splash': (
      decideEntry(
        config: ConfigStatus.ready,
        gate: GateKind.none,
        regionAllowed: true,
        maintenance: false,
        visitorMode: false,
        hasSession: false,
        sessionReady: false,
      ),
      EntryDestination.splash,
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

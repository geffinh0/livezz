/// Estado global que bloqueia o app inteiro (ENT01 decide a tela):
/// atualização obrigatória (426) ou manutenção (503).
sealed class AppGate {
  const AppGate();
}

final class GateOpen extends AppGate {
  const GateOpen();
}

final class GateUpdateRequired extends AppGate {
  const GateUpdateRequired(this.minAppVersion);
  final String? minAppVersion;
}

final class GateMaintenance extends AppGate {
  const GateMaintenance(this.retryAfter);
  final Duration? retryAfter;
}

final class GateRegionBlocked extends AppGate {
  const GateRegionBlocked(this.country);
  final String? country;
}

/// ENT10: conta ou aparelho bloqueado por menor de idade. [protocol] é o
/// número que a pessoa informa ao suporte para pedir revisão (Q-68).
final class GateMinorBlocked extends AppGate {
  const GateMinorBlocked(this.protocol);
  final String? protocol;
}

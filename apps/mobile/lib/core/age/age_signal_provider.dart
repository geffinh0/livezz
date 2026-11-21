/// Sinal de idade da loja (Play Age Signals, RN-01, Q-64). Só restringe:
/// o servidor nunca libera alguém por causa dele. Usar só para idade (termos
/// do Google: nada de analytics, publicidade ou perfilamento).
enum AgeSignalStatus { shared, notShared, verificationRequired, unavailable }

class AgeSignal {
  const AgeSignal(this.status, {this.ageLower, this.ageUpper});

  /// Sem loja, sem Play Services ou erro: o app segue só com a data.
  const AgeSignal.unavailable() : this(AgeSignalStatus.unavailable);

  final AgeSignalStatus status;
  final int? ageLower;

  /// Null = faixa mais alta (18+), ou não compartilhado.
  final int? ageUpper;

  Map<String, Object?> toJson() => {
    'status': switch (status) {
      AgeSignalStatus.shared => 'shared',
      AgeSignalStatus.notShared => 'not_shared',
      AgeSignalStatus.verificationRequired => 'verification_required',
      AgeSignalStatus.unavailable => 'unavailable',
    },
    'ageLower': ageLower,
    'ageUpper': ageUpper,
  };
}

/// Fonte do sinal. A implementação nativa (biblioteca oficial do Google Play)
/// entra na Fase 12 dentro de `lib/core/age/providers/play/`; até lá, o fake.
abstract interface class AgeSignalProvider {
  Future<AgeSignal> read();
}

/// Fake configurável (testes e builds sem loja). Padrão: indisponível.
class FakeAgeSignalProvider implements AgeSignalProvider {
  const FakeAgeSignalProvider([this.result = const AgeSignal.unavailable()]);
  final AgeSignal result;
  @override
  Future<AgeSignal> read() async => result;
}

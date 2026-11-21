import 'package:uuid/uuid.dart';

/// Anti-bot (SEG06, RN-85): obtém o token do desafio que o servidor pediu
/// (`428 desafio_necessario` com `details.providers`). Reais (App Check,
/// reCAPTCHA, Turnstile) na Fase 12, cada um atrás desta interface.
abstract interface class AntiBotProvider {
  Future<Map<String, String>?> solve(List<String> providers);
}

/// Fake: devolve um token de teste de uso único aceito pelo mock.
class FakeAntiBotProvider implements AntiBotProvider {
  const FakeAntiBotProvider();
  @override
  Future<Map<String, String>?> solve(List<String> providers) async {
    if (providers.isEmpty) return null;
    return {
      'X-Antibot-Provider': providers.first,
      'X-Antibot-Token': 'fake-ok-${const Uuid().v4()}',
    };
  }
}

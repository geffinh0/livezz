/// De onde vem o access token (Fase 0: nenhum, ou token de teste do mock;
/// Fase 1: sessão real). Evita token fixo no cliente HTTP e no tempo real.
abstract interface class TokenSource {
  Future<String?> accessToken();
}

class NoTokenSource implements TokenSource {
  const NoTokenSource();
  @override
  Future<String?> accessToken() async => null;
}

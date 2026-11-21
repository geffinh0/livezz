/// De onde vem o access token (sessão real ou token de teste do mock).
/// Evita token fixo no cliente HTTP e no tempo real.
abstract interface class TokenSource {
  Future<String?> accessToken();

  /// Renova o access token (refresh rotativo, ADR 0012). Null = não deu.
  Future<String?> refreshAccess();

  /// O servidor encerrou a sessão (`sessao_substituida`, `sessao_revogada`,
  /// `sessao_expirada`, `dispositivo_invalido`, `conta_banida`…).
  void sessionEnded(String code);
}

class NoTokenSource implements TokenSource {
  const NoTokenSource();
  @override
  Future<String?> accessToken() async => null;
  @override
  Future<String?> refreshAccess() async => null;
  @override
  void sessionEnded(String code) {}
}

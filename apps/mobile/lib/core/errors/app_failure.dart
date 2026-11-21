/// Falhas padronizadas que as features recebem (TRV03, TRV09).
/// A tela traduz por tipo/`code`; nunca mostra mensagem técnica.
sealed class AppFailure implements Exception {
  const AppFailure();
}

/// Resposta de erro da API no formato `{ error: { code, message, details, requestId } }`.
final class ApiFailure extends AppFailure {
  const ApiFailure({
    required this.status,
    required this.code,
    this.details = const {},
    this.requestId,
    this.retryAfter,
  });

  final int status;
  final String code;
  final Map<String, Object?> details;
  final String? requestId;
  final Duration? retryAfter;

  @override
  String toString() => 'ApiFailure($status, $code, requestId: $requestId)';
}

/// Sem conexão / servidor inalcançável.
final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

/// O servidor não respondeu a tempo.
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
}

/// Qualquer outra coisa (resposta fora do contrato etc.).
final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.cause]);
  final Object? cause;
}

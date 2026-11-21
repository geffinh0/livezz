import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../auth/token_source.dart';
import '../errors/app_failure.dart';
import 'app_gate.dart';

/// Marca uma requisição que mexe em valor ou cria recurso: recebe
/// `Idempotency-Key` (e a mesma chave é reusada se a requisição for repetida).
const idempotentExtra = 'idempotent';

/// Marca requisições que não levam o access token (ex.: o próprio refresh).
const noAuthExtra = 'auth.none';

/// Options para operações idempotentes. Passe `key` para reusar a mesma chave
/// ao tentar de novo após falha de rede.
Options idempotent({String? key}) => Options(
  extra: {idempotentExtra: true},
  headers: key == null ? null : {'Idempotency-Key': key},
);

typedef LanguageTag = String Function();
typedef GateListener = void Function(AppGate gate);

const _retriedExtra = 'auth.retried';

/// Códigos que significam "a sessão acabou" (ADR 0012).
const _sessionEndCodes = {
  'sessao_substituida',
  'sessao_revogada',
  'sessao_expirada',
  'dispositivo_invalido',
  'conta_banida',
  'conta_suspensa',
};

/// Cliente HTTP do app (TRV03). Base `{apiBaseUrl}/v1`.
class ApiClient {
  ApiClient({
    required String apiBaseUrl,
    required String appVersion,
    required LanguageTag language,
    required GateListener onGate,
    TokenSource tokens = const NoTokenSource(),
    HttpClientAdapter? adapter,
    Duration timeout = const Duration(seconds: 15),
  }) : dio = Dio(
         BaseOptions(
           baseUrl: '${apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}/v1',
           connectTimeout: timeout,
           receiveTimeout: timeout,
           sendTimeout: timeout,
           responseType: ResponseType.json,
         ),
       ) {
    if (adapter != null) dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept-Language'] = language();
          options.headers['X-App-Version'] = appVersion;
          if (options.extra[idempotentExtra] == true) {
            options.headers.putIfAbsent(
              'Idempotency-Key',
              () => const Uuid().v4(),
            );
          }
          if (options.extra[_retriedExtra] != true &&
              options.extra[noAuthExtra] != true) {
            final token = await tokens.accessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          final failure = mapDioException(e);
          final req = e.requestOptions;
          // Access vencido: renova uma vez e repete a requisição (ADR 0012).
          if (failure is ApiFailure &&
              failure.status == 401 &&
              failure.code == 'token_expirado' &&
              req.extra[_retriedExtra] != true &&
              req.headers.containsKey('Authorization')) {
            String? fresh;
            try {
              fresh = await tokens.refreshAccess();
            } on Object {
              fresh = null; // sem rede: devolve o erro original
            }
            if (fresh != null) {
              try {
                final retry = await dio.fetch<dynamic>(
                  req
                    ..extra[_retriedExtra] = true
                    ..headers['Authorization'] = 'Bearer $fresh',
                );
                return handler.resolve(retry);
              } on DioException catch (again) {
                return handler.next(again);
              }
            }
          }
          if (failure is ApiFailure &&
              _sessionEndCodes.contains(failure.code)) {
            final auth = req.headers['Authorization'];
            tokens.sessionEnded(
              failure.code,
              usedToken: auth is String && auth.startsWith('Bearer ')
                  ? auth.substring(7)
                  : null,
            );
          }
          if (failure is ApiFailure &&
              failure.status == 403 &&
              failure.code == 'termos_pendentes') {
            tokens.termsPending();
          }
          if (failure is ApiFailure) {
            if (failure.status == 426) {
              onGate(
                GateUpdateRequired(failure.details['minAppVersion'] as String?),
              );
            } else if (failure.status == 503 && failure.code == 'manutencao') {
              onGate(GateMaintenance(failure.retryAfter));
            } else if (failure.status == 403 &&
                failure.code == 'regiao_bloqueada') {
              onGate(GateRegionBlocked(failure.details['country'] as String?));
            }
          }
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: failure,
            ),
          );
        },
      ),
    );
  }

  final Dio dio;

  /// Executa e devolve o corpo JSON, ou lança [AppFailure].
  Future<T> call<T>(Future<Response<T>> Function(Dio dio) request) async {
    try {
      final res = await request(dio);
      return res.data as T;
    } on DioException catch (e) {
      final err = e.error;
      throw err is AppFailure ? err : mapDioException(e);
    }
  }
}

/// Converte erros do dio nas falhas padronizadas.
AppFailure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final res = e.response;
      final status = res?.statusCode ?? 0;
      final body = res?.data;
      final error = body is Map ? body['error'] : null;
      if (error is Map && error['code'] is String) {
        final retry = int.tryParse(res?.headers.value('retry-after') ?? '');
        return ApiFailure(
          status: status,
          code: error['code'] as String,
          details: error['details'] is Map
              ? Map<String, Object?>.from(error['details'] as Map)
              : const {},
          requestId: error['requestId'] as String?,
          retryAfter: retry == null ? null : Duration(seconds: retry),
        );
      }
      return ApiFailure(status: status, code: 'erro_interno');
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return e.error is AppFailure
          ? e.error! as AppFailure
          : UnknownFailure(e.error);
  }
}

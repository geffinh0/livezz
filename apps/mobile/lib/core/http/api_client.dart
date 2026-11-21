import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../auth/token_source.dart';
import '../errors/app_failure.dart';
import 'app_gate.dart';

/// Marca uma requisição que mexe em valor ou cria recurso: recebe
/// `Idempotency-Key` (e a mesma chave é reusada se a requisição for repetida).
const idempotentExtra = 'idempotent';

/// Options para operações idempotentes. Passe `key` para reusar a mesma chave
/// ao tentar de novo após falha de rede.
Options idempotent({String? key}) => Options(
  extra: {idempotentExtra: true},
  headers: key == null ? null : {'Idempotency-Key': key},
);

typedef LanguageTag = String Function();
typedef GateListener = void Function(AppGate gate);

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
          final token = await tokens.accessToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (e, handler) {
          final failure = mapDioException(e);
          if (failure is ApiFailure) {
            if (failure.status == 426) {
              onGate(
                GateUpdateRequired(failure.details['minAppVersion'] as String?),
              );
            } else if (failure.status == 503 && failure.code == 'manutencao') {
              onGate(GateMaintenance(failure.retryAfter));
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

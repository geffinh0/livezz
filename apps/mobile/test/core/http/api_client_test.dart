import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/auth/token_source.dart';
import 'package:livezz_mobile/core/errors/app_failure.dart';
import 'package:livezz_mobile/core/http/api_client.dart';
import 'package:livezz_mobile/core/http/app_gate.dart';
import 'package:livezz_mobile/core/http/page.dart';

typedef Handler = ResponseBody Function(RequestOptions o);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  Handler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(
  int status,
  Object body, {
  Map<String, List<String>> headers = const {},
}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...headers,
  },
);

class FixedToken implements TokenSource {
  @override
  Future<String?> accessToken() async => 'tkn';
}

void main() {
  late FakeAdapter adapter;
  late List<AppGate> gates;
  ApiClient client({TokenSource tokens = const NoTokenSource()}) => ApiClient(
    apiBaseUrl: 'http://localhost:3000/',
    appVersion: '0.1.0',
    language: () => 'pt-BR',
    onGate: gates.add,
    tokens: tokens,
    adapter: adapter,
  );

  setUp(() {
    gates = [];
    adapter = FakeAdapter((_) => json(200, {'ok': true}));
  });

  test('envia base /v1, Accept-Language e X-App-Version', () async {
    final r = await client().call(
      (d) => d.get<Map<String, Object?>>('/config'),
    );
    expect(r, {'ok': true});
    final req = adapter.requests.single;
    expect(req.uri.toString(), 'http://localhost:3000/v1/config');
    expect(req.headers['Accept-Language'], 'pt-BR');
    expect(req.headers['X-App-Version'], '0.1.0');
    expect(req.headers.containsKey('Authorization'), isFalse);
  });

  test('token da TokenSource vai no Authorization', () async {
    await client(tokens: FixedToken()).call((d) => d.get<Object?>('/x'));
    expect(adapter.requests.single.headers['Authorization'], 'Bearer tkn');
  });

  test(
    'operação idempotente ganha Idempotency-Key; chave dada é reusada',
    () async {
      final c = client();
      await c.call((d) => d.post<Object?>('/a', options: idempotent()));
      await c.call(
        (d) => d.post<Object?>('/a', options: idempotent(key: 'k-1')),
      );
      await c.call(
        (d) => d.post<Object?>('/a', options: idempotent(key: 'k-1')),
      );
      await c.call((d) => d.get<Object?>('/b'));
      final keys = adapter.requests.map((r) => r.headers['Idempotency-Key']);
      expect(keys.first, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(keys.skip(1).toList(), ['k-1', 'k-1', null]);
    },
  );

  test(
    'erro do contrato vira ApiFailure com code, details e requestId',
    () async {
      adapter.handler = (_) => json(402, {
        'error': {
          'code': 'saldo_insuficiente',
          'message': 'x',
          'details': {'faltam': 10},
          'requestId': 'req-1',
        },
      });
      await expectLater(
        client().call((d) => d.get<Object?>('/x')),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', 'saldo_insuficiente')
              .having((f) => f.status, 'status', 402)
              .having((f) => f.details['faltam'], 'details', 10)
              .having((f) => f.requestId, 'requestId', 'req-1'),
        ),
      );
    },
  );

  test('resposta fora do contrato vira erro_interno', () async {
    adapter.handler = (_) => json(500, 'html quebrado');
    await expectLater(
      client().call((d) => d.get<Object?>('/x')),
      throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'erro_interno')),
    );
  });

  test('426 abre o portão de atualização obrigatória', () async {
    adapter.handler = (_) => json(426, {
      'error': {
        'code': 'atualizacao_obrigatoria',
        'details': {'minAppVersion': '2.0.0'},
      },
    });
    await expectLater(
      client().call((d) => d.get<Object?>('/x')),
      throwsA(isA<ApiFailure>()),
    );
    expect(gates.single, isA<GateUpdateRequired>());
    expect((gates.single as GateUpdateRequired).minAppVersion, '2.0.0');
  });

  test('503 manutencao abre o portão com Retry-After', () async {
    adapter.handler = (_) => json(
      503,
      {
        'error': {'code': 'manutencao'},
      },
      headers: {
        'retry-after': ['300'],
      },
    );
    await expectLater(
      client().call((d) => d.get<Object?>('/x')),
      throwsA(isA<ApiFailure>()),
    );
    expect(
      (gates.single as GateMaintenance).retryAfter,
      const Duration(seconds: 300),
    );
  });

  test('403 regiao_bloqueada abre o portão de região', () async {
    adapter.handler = (_) => json(403, {
      'error': {
        'code': 'regiao_bloqueada',
        'details': {'country': 'PT'},
      },
    });
    await expectLater(
      client().call((d) => d.get<Object?>('/x')),
      throwsA(isA<ApiFailure>()),
    );
    expect((gates.single as GateRegionBlocked).country, 'PT');
  });

  test('falha de conexão vira NetworkFailure; timeout vira TimeoutFailure', () {
    final o = RequestOptions(path: '/x');
    expect(
      mapDioException(
        DioException(requestOptions: o, type: DioExceptionType.connectionError),
      ),
      isA<NetworkFailure>(),
    );
    expect(
      mapDioException(
        DioException(requestOptions: o, type: DioExceptionType.receiveTimeout),
      ),
      isA<TimeoutFailure>(),
    );
  });

  test('Page lê items e nextCursor', () {
    final p = Page<int>.fromJson({
      'items': [
        {'n': 1},
        {'n': 2},
      ],
      'nextCursor': null,
    }, (j) => j['n']! as int);
    expect(p.items, [1, 2]);
    expect(p.hasMore, isFalse);
  });
}

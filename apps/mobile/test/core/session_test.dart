import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/auth/auth_api.dart';
import 'package:livezz_mobile/core/auth/secure_store.dart';
import 'package:livezz_mobile/core/auth/session.dart';
import 'package:livezz_mobile/core/auth/token_source.dart';
import 'package:livezz_mobile/core/errors/app_failure.dart';
import 'package:livezz_mobile/core/http/api_client.dart';

/// Servidor falso com rotas de auth e uma rota protegida.
class FakeServer implements HttpClientAdapter {
  String validAccess = 'at-1';
  int refreshCalls = 0;
  String? refreshError;
  bool offline = false;
  final paths = <String>[];
  Completer<void>? refreshGate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    paths.add(o.path);
    if (offline) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    ResponseBody json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
    if (o.path == '/auth/refresh') {
      refreshCalls++;
      await refreshGate?.future;
      if (refreshError != null) {
        return json(401, {
          'error': {'code': refreshError},
        });
      }
      validAccess = 'at-${refreshCalls + 1}';
      return json(200, {
        'accessToken': validAccess,
        'refreshToken': 'rt-${refreshCalls + 1}',
        'expiresIn': 900,
        'user': {'id': 'u1', 'needsProfile': false},
      });
    }
    if (o.path == '/auth/logout') return json(204, {});
    final auth = o.headers['Authorization'];
    if (auth != 'Bearer $validAccess') {
      return json(401, {
        'error': {'code': 'token_expirado'},
      });
    }
    if (o.path == '/me') {
      return json(200, {
        'id': 'u1',
        'needsProfile': false,
        'accountStatus': 'ativa',
        'pendingTerms': [
          {'document': 'terms', 'version': 2, 'url': 'http://p/legal/termos'},
        ],
      });
    }
    return json(200, {'ok': true});
  }

  @override
  void close({bool force = false}) {}
}

class _Tokens implements TokenSource {
  _Tokens(this.c);
  final ProviderContainer c;
  SessionController get s => c.read(sessionProvider.notifier);
  @override
  Future<String?> accessToken() async => s.accessToken;
  @override
  Future<String?> refreshAccess() => s.refreshAccess();
  @override
  void sessionEnded(String code, {String? usedToken}) =>
      s.sessionEnded(code, usedToken: usedToken);
}

void main() {
  late FakeServer server;
  late MemorySecureStore store;
  late ProviderContainer c;
  late ApiClient api;

  setUp(() {
    server = FakeServer();
    store = MemorySecureStore();
    late ProviderContainer container;
    container = ProviderContainer(
      overrides: [
        sessionDepsProvider.overrideWith(
          (ref) => SessionDeps(
            api: AuthApi(api),
            store: store,
            device: () async => const DeviceCredentials(id: 'd1', secret: 's1'),
          ),
        ),
      ],
    );
    c = container;
    api = ApiClient(
      apiBaseUrl: 'http://x',
      appVersion: '0.1.0',
      language: () => 'pt-BR',
      onGate: (_) {},
      tokens: _Tokens(container),
      adapter: server,
    );
  });
  tearDown(() => c.dispose());

  Future<void> login() => c
      .read(sessionProvider.notifier)
      .signedIn(
        const TokenResponse(
          accessToken: 'at-1',
          refreshToken: 'rt-1',
          userId: 'u1',
          needsProfile: false,
        ),
      );

  test(
    'login guarda tokens no armazenamento seguro e carrega termos pendentes',
    () async {
      await login();
      expect(store.data['auth.access'], 'at-1');
      expect(store.data['auth.refresh'], 'rt-1');
      expect(c.read(sessionProvider)?.pendingTerms.single.version, 2);
    },
  );

  test('token vencido: renova uma vez e repete a chamada', () async {
    await login();
    server.validAccess = 'outro'; // o at-1 "venceu"
    final r = await api.call((d) => d.get<Map<String, dynamic>>('/protegida'));
    expect(r, {'ok': true});
    expect(server.refreshCalls, 1);
    expect(store.data['auth.refresh'], 'rt-2');
  });

  test(
    'várias chamadas com token vencido disparam uma única renovação',
    () async {
      await login();
      server
        ..validAccess = 'outro'
        ..refreshGate = Completer<void>();
      final calls = [
        for (var i = 0; i < 3; i++)
          api.call((d) => d.get<Map<String, dynamic>>('/protegida')),
      ];
      await Future<void>.delayed(const Duration(milliseconds: 20));
      server.refreshGate!.complete();
      await Future.wait(calls);
      expect(server.refreshCalls, 1);
    },
  );

  test('renovação recusada (sessao_substituida) encerra a sessão e guarda o motivo', () async {
    await login();
    server
      ..validAccess = 'outro'
      ..refreshError = 'sessao_substituida';
    await expectLater(
      api.call((d) => d.get<Object?>('/protegida')),
      throwsA(anything),
    );
    await Future<void>.delayed(Duration.zero);
    expect(c.read(sessionProvider), isNull);
    expect(c.read(sessionEndNoticeProvider), 'sessao_substituida');
    expect(store.data, isEmpty);
  });

  test('sair limpa tudo mesmo sem rede', () async {
    await login();
    server.offline = true;
    await c.read(sessionProvider.notifier).signOut();
    expect(c.read(sessionProvider), isNull);
    expect(store.data.containsKey('auth.access'), isFalse);
  });

  test('restaura sessão guardada ao abrir (ENT01)', () async {
    store.data.addAll({
      'auth.access': 'at-1',
      'auth.refresh': 'rt-1',
      'auth.user': 'u1',
    });
    await c.read(sessionProvider.notifier).restore();
    expect(c.read(sessionProvider)?.userId, 'u1');
    expect(c.read(sessionProvider)?.pendingTerms, hasLength(1));
  });

  test(
    'restaurar com sessão revogada no servidor volta para sem sessão',
    () async {
      store.data.addAll({
        'auth.access': 'at-x',
        'auth.refresh': 'rt-x',
        'auth.user': 'u1',
      });
      server.refreshError = 'sessao_revogada';
      await c.read(sessionProvider.notifier).restore();
      expect(c.read(sessionProvider), isNull);
      expect(store.data.containsKey('auth.refresh'), isFalse);
    },
  );

  test('sair durante uma renovação não ressuscita a sessão', () async {
    await login();
    server
      ..validAccess = 'outro'
      ..refreshGate = Completer<void>();
    final pending = c.read(sessionProvider.notifier).refreshAccess();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await c.read(sessionProvider.notifier).signOut();
    server.refreshGate!.complete();
    expect(await pending, isNull);
    expect(c.read(sessionProvider), isNull);
    expect(store.data.containsKey('auth.access'), isFalse);
  });

  test('novo login durante uma renovação não é sobrescrito', () async {
    await login();
    server.refreshGate = Completer<void>();
    final pending = c.read(sessionProvider.notifier).refreshAccess();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await c
        .read(sessionProvider.notifier)
        .signedIn(
          const TokenResponse(
            accessToken: 'at-novo',
            refreshToken: 'rt-novo',
            userId: 'u1',
            needsProfile: false,
          ),
        );
    server.refreshGate!.complete();
    await pending;
    expect(store.data['auth.access'], 'at-novo');
    expect(store.data['auth.refresh'], 'rt-novo');
  });

  test(
    'resposta atrasada de sessão antiga não derruba a sessão nova',
    () async {
      await login();
      c
          .read(sessionProvider.notifier)
          .sessionEnded('sessao_revogada', usedToken: 'token-antigo');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(sessionProvider), isNotNull);
    },
  );

  test(
    'sem rede, renovar lança NetworkFailure e não encerra a sessão',
    () async {
      await login();
      server.offline = true;
      await expectLater(
        c.read(sessionProvider.notifier).refreshAccess(),
        throwsA(isA<NetworkFailure>()),
      );
      expect(c.read(sessionProvider), isNotNull);
    },
  );
}

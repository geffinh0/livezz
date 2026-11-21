import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/auth/token_source.dart';
import 'package:livezz_mobile/core/realtime/envelope.dart';
import 'package:livezz_mobile/core/realtime/event_types.dart';
import 'package:livezz_mobile/core/realtime/realtime_client.dart';
import 'package:livezz_mobile/core/realtime/transport.dart';

class FakeSocket implements RealtimeSocket {
  final incoming = StreamController<Object?>();
  final sent = <Map<String, dynamic>>[];
  bool closed = false;
  @override
  int? closeCode;

  @override
  Stream<Object?> get messages => incoming.stream;

  @override
  void send(String text) => sent.add(jsonDecode(text) as Map<String, dynamic>);

  @override
  Future<void> close([int? code]) async {
    closed = true;
    await incoming.close();
  }

  List<String> get types => [for (final m in sent) m['type'] as String];

  static int _n = 0;
  void serverSends(
    String type,
    Map<String, Object?> data, {
    String? id,
    int v = 1,
  }) {
    incoming.add(
      jsonEncode({
        'v': v,
        'id': id ?? 'srv-${_n++}',
        'type': type,
        'ts': '2026-11-21T00:00:00Z',
        'data': data,
      }),
    );
  }

  void ackAuth({bool ok = true}) {
    final auth = sent.firstWhere((m) => m['type'] == 'auth');
    serverSends('ack', {'refId': auth['id'], 'ok': ok});
  }

  void serverCloses([int? code]) {
    closeCode = code;
    unawaited(incoming.close());
  }
}

class Token implements TokenSource {
  Token(this.value);
  String? value;
  String? renewed;
  int refreshes = 0;
  @override
  Future<String?> accessToken() async => value;
  @override
  Future<String?> refreshAccess() async {
    refreshes++;
    if (renewed != null) value = renewed;
    return renewed;
  }

  @override
  void sessionEnded(String code) {}
}

void main() {
  late List<FakeSocket> sockets;
  late Token token;

  RealtimeClient client() => RealtimeClient(
    uri: Uri.parse('ws://x/v1/realtime'),
    tokens: token,
    random: Random(1),
    connector: (_) async {
      final s = FakeSocket();
      sockets.add(s);
      return s;
    },
  );

  setUp(() {
    sockets = [];
    token = Token('dev-token-u-ana');
  });

  test('autentica, fica conectado e re-entra nas salas ao reconectar', () {
    fakeAsync((async) {
      final c = client()..join('live:1');
      final statuses = <RealtimeStatus>[];
      var reconnects = 0;
      c.statusChanges.listen(statuses.add);
      c.reconnected.listen((_) => reconnects++);
      unawaited(c.start());
      async.flushMicrotasks();
      final s1 = sockets.single;
      expect(s1.sent.first['type'], 'auth');
      expect(s1.sent.first['data'], {'token': 'dev-token-u-ana'});
      expect(s1.sent.first['v'], 1);
      s1.ackAuth();
      async.flushMicrotasks();
      expect(c.status, RealtimeStatus.connected);
      expect(s1.types, ['auth', 'room.join']);

      s1.serverCloses(1006); // queda
      async.flushMicrotasks();
      expect(c.status, RealtimeStatus.connecting);
      async.elapse(const Duration(milliseconds: 1300));
      final s2 = sockets.last;
      expect(sockets, hasLength(2));
      s2.ackAuth();
      async.flushMicrotasks();
      expect(s2.types, ['auth', 'room.join']);
      expect(reconnects, 1);
      expect(statuses, [
        RealtimeStatus.connecting,
        RealtimeStatus.connected,
        RealtimeStatus.connecting,
        RealtimeStatus.connected,
      ]);
      unawaited(c.dispose());
    });
  });

  test('backoff exponencial com jitter até 30 s', () {
    final c = client();
    for (var i = 0; i < 8; i++) {
      final d = c.backoffFor(i).inMilliseconds;
      final base = min(1000 * pow(2, i), 30000);
      expect(
        d,
        inInclusiveRange(base * 0.8, base * 1.2),
        reason: 'tentativa $i',
      );
    }
  });

  test('sem pong em 10 s derruba e reconecta', () {
    fakeAsync((async) {
      final c = client();
      unawaited(c.start());
      async.flushMicrotasks();
      sockets.single.ackAuth();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 25));
      expect(sockets.single.types.last, 'ping');
      async.elapse(const Duration(seconds: 10));
      expect(sockets.first.closed, isTrue);
      async.elapse(const Duration(seconds: 2));
      expect(sockets, hasLength(2));
      unawaited(c.dispose());
    });
  });

  test('pong a tempo mantém a conexão', () {
    fakeAsync((async) {
      final c = client();
      unawaited(c.start());
      async.flushMicrotasks();
      final s = sockets.single..ackAuth();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 25));
      s.serverSends('pong', {});
      async.elapse(const Duration(seconds: 15));
      expect(s.closed, isFalse);
      expect(sockets, hasLength(1));
      unawaited(c.dispose());
    });
  });

  test(
    'entrega eventos conhecidos; ignora desconhecido, v maior e duplicado',
    () {
      fakeAsync((async) {
        final c = client();
        final got = <String>[];
        c.events.listen((e) => got.add('${e.type}#${e.id}'));
        unawaited(c.start());
        async.flushMicrotasks();
        final s = sockets.single..ackAuth();
        async.flushMicrotasks();
        s
          ..serverSends('live.likes', {'total': 1}, id: 'e1')
          ..serverSends('live.likes', {'total': 1}, id: 'e1')
          ..serverSends('tipo.inventado', {}, id: 'e2')
          ..serverSends('live.likes', {}, id: 'e3', v: 2)
          ..incoming.add('não é json')
          ..serverSends('config.updated', {'configVersion': 2}, id: 'e4');
        async.flushMicrotasks();
        expect(got, ['live.likes#e1', 'config.updated#e4']);
        unawaited(c.dispose());
      });
    },
  );

  test('session.replaced encerra sem reconectar', () {
    fakeAsync((async) {
      final c = client();
      final ends = <RealtimeEnd>[];
      c.ended.listen(ends.add);
      unawaited(c.start());
      async.flushMicrotasks();
      sockets.single
        ..ackAuth()
        ..serverSends('session.replaced', {'at': 'x'});
      async.flushMicrotasks();
      sockets.single.serverCloses(4002);
      async.elapse(const Duration(minutes: 1));
      expect(ends, [RealtimeEnd.replaced]);
      expect(sockets, hasLength(1));
      expect(c.status, RealtimeStatus.disconnected);
      unawaited(c.dispose());
    });
  });

  test('fechamento 4001 (token inválido) encerra sem reconectar', () {
    fakeAsync((async) {
      final c = client();
      final ends = <RealtimeEnd>[];
      c.ended.listen(ends.add);
      unawaited(c.start());
      async.flushMicrotasks();
      sockets.single.serverCloses(4001);
      async.elapse(const Duration(minutes: 1));
      expect(ends, [RealtimeEnd.invalidToken]);
      expect(sockets, hasLength(1));
      unawaited(c.dispose());
    });
  });

  test('sem token (antes do login) não conecta', () {
    fakeAsync((async) {
      token.value = null;
      final c = client();
      unawaited(c.start());
      async.elapse(const Duration(minutes: 1));
      expect(sockets, isEmpty);
      expect(c.status, RealtimeStatus.disconnected);
      unawaited(c.dispose());
    });
  });

  test('join/leave conectado enviam room.join/room.leave', () {
    fakeAsync((async) {
      final c = client();
      unawaited(c.start());
      async.flushMicrotasks();
      final s = sockets.single..ackAuth();
      async.flushMicrotasks();
      c
        ..join('pk:9')
        ..join('pk:9')
        ..leave('pk:9');
      expect(s.types, ['auth', 'room.join', 'room.leave']);
      expect(s.sent[1]['data'], {'room': 'pk:9'});
      unawaited(c.dispose());
    });
  });

  test('catálogo do app bate com docs/EVENTOS-TEMPO-REAL.md', () {
    final md = File('../../docs/EVENTOS-TEMPO-REAL.md').readAsStringSync();
    final start = md.indexOf('## Servidor → cliente');
    final end = md.indexOf('\n## ', start + 1);
    final documented = <String>{};
    for (final line in md.substring(start, end).split('\n')) {
      final m = RegExp(r'^\| ([a-z][a-z0-9_.]*(?: / [a-z][a-z0-9_.]*)*) \|')
          .firstMatch(line);
      if (m == null || m.group(1) == 'type') continue;
      documented.addAll(m.group(1)!.split(' / '));
    }
    expect(knownServerEventTypes, documented);
  });

  test('Envelope.tryParse rejeita formato inválido', () {
    expect(Envelope.tryParse('{}'), isNull);
    expect(Envelope.tryParse(42), isNull);
    expect(
      Envelope.tryParse(
        '{"v":1,"id":"a","type":"pong","ts":"2026-11-21T00:00:00Z","data":{}}',
      )?.type,
      'pong',
    );
  });

  test('token vencido (4003) renova e reconecta com o token novo', () {
    fakeAsync((async) {
      token.renewed = 'novo-token';
      final c = client();
      final ends = <RealtimeEnd>[];
      c.ended.listen(ends.add);
      unawaited(c.start());
      async.flushMicrotasks();
      sockets.single
        ..serverSends('session.invalid', {'reason': 'token_expirado'})
        ..serverCloses(4003);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));
      expect(token.refreshes, 1);
      expect(sockets, hasLength(2));
      expect(sockets.last.sent.first['data'], {'token': 'novo-token'});
      expect(ends, isEmpty);
      unawaited(c.dispose());
    });
  });

  test('token vencido sem conseguir renovar encerra como revogada', () {
    fakeAsync((async) {
      final c = client();
      final ends = <RealtimeEnd>[];
      c.ended.listen(ends.add);
      unawaited(c.start());
      async.flushMicrotasks();
      sockets.single.serverCloses(4003);
      async.elapse(const Duration(seconds: 5));
      expect(ends, [RealtimeEnd.revoked]);
      expect(sockets, hasLength(1));
      unawaited(c.dispose());
    });
  });

  test(
    'session.invalid revogada encerra como revoked; 4004 para sem reconectar',
    () {
      fakeAsync((async) {
        final c = client();
        final ends = <RealtimeEnd>[];
        c.ended.listen(ends.add);
        unawaited(c.start());
        async.flushMicrotasks();
        sockets.single
          ..ackAuth()
          ..serverSends('session.invalid', {'reason': 'senha_trocada'});
        async.flushMicrotasks();
        expect(ends, [RealtimeEnd.revoked]);
        unawaited(c.dispose());

        final c2 = client();
        unawaited(c2.start());
        async.flushMicrotasks();
        sockets.last.serverCloses(4004);
        async.elapse(const Duration(minutes: 1));
        expect(c2.status, RealtimeStatus.disconnected);
        unawaited(c2.dispose());
      });
    },
  );
}

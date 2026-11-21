import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../auth/token_source.dart';
import 'envelope.dart';
import 'event_types.dart';
import 'transport.dart';

enum RealtimeStatus { disconnected, connecting, connected }

/// Por que a sessão de tempo real acabou sem reconexão automática.
enum RealtimeEnd { invalidToken, replaced }

/// Códigos de fechamento (docs/EVENTOS-TEMPO-REAL.md).
abstract final class RealtimeCloseCodes {
  static const authTimeout = 4000;
  static const invalidToken = 4001;
  static const replaced = 4002;
}

/// Cliente de tempo real (TRV01): envelope versionado, autenticação,
/// heartbeat, reconexão exponencial com jitter, re-entrada em salas,
/// deduplicação por `id` e descarte de tipos desconhecidos.
class RealtimeClient {
  RealtimeClient({
    required this.uri,
    required this.tokens,
    this._connector = connectWebSocket,
    Random? random,
    this.pingInterval = const Duration(seconds: 25),
    this.pongTimeout = const Duration(seconds: 10),
    this.authTimeout = const Duration(seconds: 10),
    this.minBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
    this._knownTypes = knownServerEventTypes,
  }) : _random = random ?? Random();

  final Uri uri;
  final TokenSource tokens;
  final Duration pingInterval;
  final Duration pongTimeout;
  final Duration authTimeout;
  final Duration minBackoff;
  final Duration maxBackoff;
  final RealtimeConnector _connector;
  final Random _random;
  final Set<String> _knownTypes;

  final _events = StreamController<Envelope>.broadcast();
  final _status = StreamController<RealtimeStatus>.broadcast();
  final _reconnected = StreamController<void>.broadcast();
  final _ended = StreamController<RealtimeEnd>.broadcast();
  final _rooms = <String>{};
  final _seen =
      <String>{}; // LinkedHashSet: mantém ordem para descartar os antigos
  static const _seenLimit = 500;

  RealtimeSocket? _socket;
  // Cancelada em _teardown.
  // ignore: cancel_subscriptions
  StreamSubscription<Object?>? _sub;
  Timer? _pingTimer;
  Timer? _pongTimer;
  Timer? _authTimer;
  Timer? _retryTimer;
  String? _authId;
  int _attempt = 0;
  bool _everConnected = false;
  bool _wanted = false;
  bool _disposed = false;
  RealtimeStatus _current = RealtimeStatus.disconnected;

  /// Eventos do servidor já validados e sem duplicatas.
  Stream<Envelope> get events => _events.stream;
  Stream<Envelope> on(String type) => events.where((e) => e.type == type);
  Stream<RealtimeStatus> get statusChanges => _status.stream;
  RealtimeStatus get status => _current;

  /// Disparado após uma reconexão: as features devem rebuscar estado por REST.
  Stream<void> get reconnected => _reconnected.stream;

  /// Sessão encerrada pelo servidor (token inválido ou conta em outro aparelho).
  Stream<RealtimeEnd> get ended => _ended.stream;

  Set<String> get rooms => Set.unmodifiable(_rooms);

  /// Liga o cliente. Sem token (antes do login) não conecta (ADR 0011).
  Future<void> start() async {
    _wanted = true;
    await _open();
  }

  /// Desliga sem reconectar (logout, app fechado).
  Future<void> stop() async {
    _wanted = false;
    _retryTimer?.cancel();
    await _teardown(closeSocket: true);
    _setStatus(RealtimeStatus.disconnected);
  }

  void join(String room) {
    if (_rooms.add(room) && _current == RealtimeStatus.connected) {
      _send('room.join', {'room': room});
    }
  }

  void leave(String room) {
    if (_rooms.remove(room) && _current == RealtimeStatus.connected) {
      _send('room.leave', {'room': room});
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await Future.wait([
      _events.close(),
      _status.close(),
      _reconnected.close(),
      _ended.close(),
    ]);
  }

  /// Atraso da tentativa [attempt] (0 = primeira): 1, 2, 4… até 30 s, ±20%.
  Duration backoffFor(int attempt) {
    final base = minBackoff.inMilliseconds * pow(2, attempt);
    final capped = min(base.toDouble(), maxBackoff.inMilliseconds.toDouble());
    final jitter = 0.8 + _random.nextDouble() * 0.4;
    return Duration(milliseconds: (capped * jitter).round());
  }

  Future<void> _open() async {
    if (!_wanted || _disposed || _socket != null) return;
    final token = await tokens.accessToken();
    if (token == null) {
      _setStatus(RealtimeStatus.disconnected);
      return;
    }
    _setStatus(RealtimeStatus.connecting);
    try {
      final socket = await _connector(uri);
      if (!_wanted || _disposed) {
        await socket.close();
        return;
      }
      _socket = socket;
      _sub = socket.messages.listen(
        _onMessage,
        onDone: _onClosed,
        onError: (Object _) => _onClosed(),
      );
      _authId = const Uuid().v4();
      socket.send(Envelope.encode(_authId!, 'auth', {'token': token}));
      _authTimer = Timer(authTimeout, _drop);
    } on Object catch (e) {
      _log('falha ao conectar: $e');
      _scheduleRetry();
    }
  }

  void _onMessage(Object? raw) {
    final e = Envelope.tryParse(raw);
    if (e == null) {
      _log('mensagem fora do envelope ignorada');
      return;
    }
    if (e.v > Envelope.supportedVersion) {
      _log('versão ${e.v} não suportada: ${e.type}');
      return;
    }
    if (!_seen.add(e.id)) return; // duplicado
    if (_seen.length > _seenLimit) _seen.remove(_seen.first);

    switch (e.type) {
      case 'ack' when e.data['refId'] == _authId:
        _authTimer?.cancel();
        if (e.data['ok'] == true) {
          _onAuthenticated();
        } else {
          _drop();
        }
        return;
      case 'pong':
        _pongTimer?.cancel();
        return;
      case 'session.invalid':
        _end(RealtimeEnd.invalidToken);
        return;
      case 'session.replaced':
        _end(RealtimeEnd.replaced);
        return;
    }
    if (!_knownTypes.contains(e.type)) {
      _log('tipo desconhecido ignorado: ${e.type}');
      return;
    }
    _events.add(e);
  }

  void _onAuthenticated() {
    _attempt = 0;
    _setStatus(RealtimeStatus.connected);
    for (final room in _rooms) {
      _send('room.join', {'room': room});
    }
    _pingTimer = Timer.periodic(pingInterval, (_) {
      _send('ping', const {});
      _pongTimer?.cancel();
      _pongTimer = Timer(pongTimeout, _drop);
    });
    if (_everConnected) _reconnected.add(null);
    _everConnected = true;
  }

  void _onClosed() {
    final code = _socket?.closeCode;
    unawaited(_teardown(closeSocket: false));
    if (code == RealtimeCloseCodes.invalidToken) {
      _end(RealtimeEnd.invalidToken);
    } else if (code == RealtimeCloseCodes.replaced) {
      _end(RealtimeEnd.replaced);
    } else {
      _scheduleRetry();
    }
  }

  /// Conexão ruim (sem pong, sem ack): derruba e tenta de novo.
  void _drop() {
    unawaited(_teardown(closeSocket: true));
    _scheduleRetry();
  }

  void _end(RealtimeEnd reason) {
    _wanted = false;
    _retryTimer?.cancel();
    unawaited(_teardown(closeSocket: true));
    _setStatus(RealtimeStatus.disconnected);
    if (!_ended.isClosed) _ended.add(reason);
  }

  void _scheduleRetry() {
    if (!_wanted || _disposed) {
      _setStatus(RealtimeStatus.disconnected);
      return;
    }
    _setStatus(RealtimeStatus.connecting);
    _retryTimer?.cancel();
    final delay = backoffFor(_attempt);
    _attempt++;
    _retryTimer = Timer(delay, () => unawaited(_open()));
  }

  Future<void> _teardown({required bool closeSocket}) async {
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    _authTimer?.cancel();
    final sub = _sub;
    final socket = _socket;
    _sub = null;
    _socket = null;
    if (closeSocket) unawaited(socket?.close());
    await sub?.cancel();
  }

  void _send(String type, Map<String, Object?> data) {
    _socket?.send(Envelope.encode(const Uuid().v4(), type, data));
  }

  void _setStatus(RealtimeStatus s) {
    if (_current == s || _status.isClosed) return;
    _current = s;
    _status.add(s);
  }

  void _log(String msg) => developer.log(msg, name: 'realtime');
}

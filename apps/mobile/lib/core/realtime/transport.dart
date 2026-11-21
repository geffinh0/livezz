import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Uma conexão aberta. Abstrai o WebSocket para os testes.
abstract interface class RealtimeSocket {
  Stream<Object?> get messages;
  void send(String text);
  Future<void> close([int? code]);

  /// Código de fechamento informado pelo servidor (ex.: 4002).
  int? get closeCode;
}

typedef RealtimeConnector = Future<RealtimeSocket> Function(Uri uri);

/// Implementação real com `web_socket_channel`.
Future<RealtimeSocket> connectWebSocket(Uri uri) async {
  final channel = WebSocketChannel.connect(uri);
  await channel.ready;
  return _ChannelSocket(channel);
}

class _ChannelSocket implements RealtimeSocket {
  _ChannelSocket(this._channel);
  final WebSocketChannel _channel;

  @override
  Stream<Object?> get messages => _channel.stream;

  @override
  void send(String text) => _channel.sink.add(text);

  @override
  Future<void> close([int? code]) async {
    await _channel.sink.close(code);
  }

  @override
  int? get closeCode => _channel.closeCode;
}

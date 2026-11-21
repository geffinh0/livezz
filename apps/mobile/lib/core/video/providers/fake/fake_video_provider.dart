import 'dart:async';

import '../../video_provider.dart';
import '../../video_state.dart';

/// Vídeo simulado (ADR 0003). Só estado em Dart puro (testável); a imagem é
/// desenhada por `FakeVideoView`. Emite os mesmos estados do provedor real e
/// permite simular convidados, qualidade e quedas.
class FakeVideoProvider implements VideoProvider {
  FakeVideoProvider({this.joinDelay = const Duration(milliseconds: 300)});

  final Duration joinDelay;
  final _controller = StreamController<VideoState>.broadcast();
  VideoState _state = const VideoState();

  @override
  VideoState get state => _state;

  @override
  Stream<VideoState> get states => _controller.stream;

  void _emit(VideoState s) {
    _state = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  Future<void> _join(
    String channelId,
    VideoCredentials c,
    VideoRole role,
  ) async {
    if (c.token.isEmpty) {
      _emit(_state.copyWith(connection: VideoConnection.failed));
      throw ArgumentError('token de vídeo ausente');
    }
    _emit(
      VideoState(
        connection: VideoConnection.connecting,
        role: role,
        channelId: channelId,
      ),
    );
    await Future<void>.delayed(joinDelay);
    final host = role == VideoRole.host;
    _emit(
      _state.copyWith(
        connection: VideoConnection.connected,
        quality: VideoQuality.good,
        micOn: host,
        cameraOn: host,
        participants: [
          VideoParticipant(
            uid: c.uid,
            isLocal: true,
            micOn: host,
            cameraOn: host,
          ),
          if (!host) VideoParticipant(uid: 'host-$channelId', isLocal: false),
        ],
      ),
    );
  }

  @override
  Future<void> joinAsHost({
    required String channelId,
    required VideoCredentials credentials,
  }) => _join(channelId, credentials, VideoRole.host);

  @override
  Future<void> joinAsAudience({
    required String channelId,
    required VideoCredentials credentials,
  }) => _join(channelId, credentials, VideoRole.audience);

  @override
  Future<void> leave() async => _emit(const VideoState());

  void _requireHost() {
    if (_state.role != VideoRole.host) {
      throw StateError('só o host controla câmera e microfone');
    }
  }

  List<VideoParticipant> _updateLocal({bool? mic, bool? camera}) => [
    for (final p in _state.participants)
      p.isLocal ? p.copyWith(micOn: mic, cameraOn: camera) : p,
  ];

  @override
  Future<void> setMic({required bool on}) async {
    _requireHost();
    _emit(
      _state.copyWith(
        micOn: on,
        participants: _updateLocal(mic: on),
      ),
    );
  }

  @override
  Future<void> setCamera({required bool on}) async {
    _requireHost();
    _emit(
      _state.copyWith(
        cameraOn: on,
        participants: _updateLocal(camera: on),
      ),
    );
  }

  @override
  Future<void> switchCamera() async {
    _requireHost();
    _emit(_state.copyWith(frontCamera: !_state.frontCamera));
  }

  @override
  Future<void> startRelay({
    required String targetChannelId,
    required VideoCredentials credentials,
  }) async {
    _requireHost();
    _emit(
      _state.copyWith(
        relayChannelId: targetChannelId,
        participants: [
          ..._state.participants,
          VideoParticipant(uid: 'host-$targetChannelId', isLocal: false),
        ],
      ),
    );
  }

  @override
  Future<void> stopRelay() async {
    final target = _state.relayChannelId;
    if (target == null) return;
    _emit(
      _state.copyWith(
        clearRelay: true,
        participants: [
          for (final p in _state.participants)
            if (p.uid != 'host-$target') p,
        ],
      ),
    );
  }

  // --- Simulações (só no fake) ---

  void simulateGuestJoined(String uid) => _emit(
    _state.copyWith(
      participants: [
        ..._state.participants,
        VideoParticipant(uid: uid, isLocal: false),
      ],
    ),
  );

  void simulateGuestLeft(String uid) => _emit(
    _state.copyWith(
      participants: [
        for (final p in _state.participants)
          if (p.uid != uid) p,
      ],
    ),
  );

  void simulateQuality(VideoQuality q) => _emit(_state.copyWith(quality: q));

  void simulateConnectionLost() =>
      _emit(_state.copyWith(connection: VideoConnection.reconnecting));

  void simulateConnectionRestored() =>
      _emit(_state.copyWith(connection: VideoConnection.connected));

  @override
  Future<void> dispose() async => _controller.close();
}

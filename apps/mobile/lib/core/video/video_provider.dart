import 'video_state.dart';

/// Credenciais de vídeo SEMPRE emitidas pelo servidor (token curto, papel
/// correto). O app nunca gera token nem guarda segredo do provedor.
class VideoCredentials {
  const VideoCredentials({required this.uid, required this.token});
  final String uid;
  final String token;
}

/// Camada de vídeo (TRV02, ADR 0003). Fake agora; Agora na Fase 12, só em
/// `lib/core/video/providers/agora/`.
abstract interface class VideoProvider {
  VideoState get state;
  Stream<VideoState> get states;

  Future<void> joinAsHost({
    required String channelId,
    required VideoCredentials credentials,
  });

  Future<void> joinAsAudience({
    required String channelId,
    required VideoCredentials credentials,
  });

  Future<void> leave();
  Future<void> switchCamera();
  Future<void> setMic({required bool on});
  Future<void> setCamera({required bool on});

  /// Relay de mídia para PK (tela dividida).
  Future<void> startRelay({
    required String targetChannelId,
    required VideoCredentials credentials,
  });

  Future<void> stopRelay();

  Future<void> dispose();
}

/// Filtros de beleza (Q-10: beleza básica da Agora). No-op até a Fase 12.
class BeautyOptions {
  const BeautyOptions({this.enabled = false, this.smoothness = 0});
  final bool enabled;

  /// 0–100.
  final int smoothness;
}

abstract interface class BeautyProvider {
  Future<void> apply(BeautyOptions options);
}

class NoopBeautyProvider implements BeautyProvider {
  const NoopBeautyProvider();
  @override
  Future<void> apply(BeautyOptions options) async {}
}

/// Estado do vídeo exposto pelo `VideoProvider` (o mesmo para fake e Agora).
enum VideoConnection { idle, connecting, connected, reconnecting, failed }

enum VideoRole { none, host, audience }

enum VideoQuality { unknown, good, fair, poor }

class VideoParticipant {
  const VideoParticipant({
    required this.uid,
    required this.isLocal,
    this.micOn = true,
    this.cameraOn = true,
  });

  final String uid;
  final bool isLocal;
  final bool micOn;
  final bool cameraOn;

  VideoParticipant copyWith({bool? micOn, bool? cameraOn}) => VideoParticipant(
    uid: uid,
    isLocal: isLocal,
    micOn: micOn ?? this.micOn,
    cameraOn: cameraOn ?? this.cameraOn,
  );

  @override
  bool operator ==(Object other) =>
      other is VideoParticipant &&
      other.uid == uid &&
      other.isLocal == isLocal &&
      other.micOn == micOn &&
      other.cameraOn == cameraOn;

  @override
  int get hashCode => Object.hash(uid, isLocal, micOn, cameraOn);
}

class VideoState {
  const VideoState({
    this.connection = VideoConnection.idle,
    this.role = VideoRole.none,
    this.channelId,
    this.quality = VideoQuality.unknown,
    this.micOn = false,
    this.cameraOn = false,
    this.frontCamera = true,
    this.participants = const [],
    this.relayChannelId,
  });

  final VideoConnection connection;
  final VideoRole role;
  final String? channelId;
  final VideoQuality quality;
  final bool micOn;
  final bool cameraOn;
  final bool frontCamera;
  final List<VideoParticipant> participants;

  /// Canal remoto do relay de PK, quando ativo.
  final String? relayChannelId;

  VideoState copyWith({
    VideoConnection? connection,
    VideoRole? role,
    String? channelId,
    VideoQuality? quality,
    bool? micOn,
    bool? cameraOn,
    bool? frontCamera,
    List<VideoParticipant>? participants,
    String? relayChannelId,
    bool clearRelay = false,
  }) => VideoState(
    connection: connection ?? this.connection,
    role: role ?? this.role,
    channelId: channelId ?? this.channelId,
    quality: quality ?? this.quality,
    micOn: micOn ?? this.micOn,
    cameraOn: cameraOn ?? this.cameraOn,
    frontCamera: frontCamera ?? this.frontCamera,
    participants: participants ?? this.participants,
    relayChannelId: clearRelay ? null : relayChannelId ?? this.relayChannelId,
  );
}

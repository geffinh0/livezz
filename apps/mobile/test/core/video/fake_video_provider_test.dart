import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/video/providers/fake/fake_video_provider.dart';
import 'package:livezz_mobile/core/video/video_provider.dart';
import 'package:livezz_mobile/core/video/video_state.dart';

const cred = VideoCredentials(uid: 'u-ana', token: 'tok-servidor');

void main() {
  test('host entra: connecting → connected com câmera e mic ligados', () {
    fakeAsync((async) {
      final v = FakeVideoProvider();
      final seen = <VideoConnection>[];
      v.states.listen((s) => seen.add(s.connection));
      v.joinAsHost(channelId: 'live-1', credentials: cred);
      async.elapse(const Duration(milliseconds: 300));
      expect(seen, [VideoConnection.connecting, VideoConnection.connected]);
      expect(v.state.role, VideoRole.host);
      expect(v.state.micOn && v.state.cameraOn, isTrue);
      expect(v.state.participants.single.isLocal, isTrue);
    });
  });

  test('espectador vê o host remoto e não controla câmera', () async {
    final v = FakeVideoProvider(joinDelay: Duration.zero);
    await v.joinAsAudience(channelId: 'live-1', credentials: cred);
    expect(v.state.participants.map((p) => p.uid), ['u-ana', 'host-live-1']);
    expect(() => v.setMic(on: true), throwsStateError);
  });

  test('token vazio falha (token vem do servidor)', () async {
    final v = FakeVideoProvider(joinDelay: Duration.zero);
    await expectLater(
      v.joinAsHost(
        channelId: 'x',
        credentials: const VideoCredentials(uid: 'u', token: ''),
      ),
      throwsArgumentError,
    );
    expect(v.state.connection, VideoConnection.failed);
  });

  test('mic, câmera, troca de câmera, convidados e relay de PK', () async {
    final v = FakeVideoProvider(joinDelay: Duration.zero);
    await v.joinAsHost(channelId: 'live-1', credentials: cred);
    await v.setMic(on: false);
    await v.setCamera(on: false);
    await v.switchCamera();
    expect(v.state.micOn, isFalse);
    expect(v.state.participants.single.cameraOn, isFalse);
    expect(v.state.frontCamera, isFalse);

    v.simulateGuestJoined('g1');
    expect(v.state.participants, hasLength(2));
    v.simulateGuestLeft('g1');
    expect(v.state.participants, hasLength(1));

    await v.startRelay(targetChannelId: 'live-2', credentials: cred);
    expect(v.state.relayChannelId, 'live-2');
    expect(v.state.participants.last.uid, 'host-live-2');
    await v.stopRelay();
    expect(v.state.relayChannelId, isNull);
    expect(v.state.participants, hasLength(1));
  });

  test('qualidade e queda simuladas; leave volta ao inicial', () async {
    final v = FakeVideoProvider(joinDelay: Duration.zero);
    await v.joinAsAudience(channelId: 'live-1', credentials: cred);
    v.simulateQuality(VideoQuality.poor);
    v.simulateConnectionLost();
    expect(v.state.connection, VideoConnection.reconnecting);
    v.simulateConnectionRestored();
    expect(v.state.quality, VideoQuality.poor);
    await v.leave();
    expect(v.state.connection, VideoConnection.idle);
    expect(v.state.role, VideoRole.none);
  });

  test('beleza no-op aceita opções', () async {
    await const NoopBeautyProvider().apply(
      const BeautyOptions(enabled: true, smoothness: 50),
    );
  });
}

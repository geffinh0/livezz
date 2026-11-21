import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/auth/token_source.dart';
import 'package:livezz_mobile/core/config/data/app_config_dto.dart';
import 'package:livezz_mobile/core/http/api_client.dart';
import 'package:livezz_mobile/core/realtime/realtime_client.dart';

/// Integração com o mock-server real. Roda só com:
///   MOCK_SERVER_URL=http://127.0.0.1:3000 flutter test test/integration
final _url = Platform.environment['MOCK_SERVER_URL'];

class _Dev implements TokenSource {
  @override
  Future<String?> accessToken() async => 'dev-token-u-ana';
  @override
  Future<String?> refreshAccess() async => null;
  @override
  void sessionEnded(String code, {String? usedToken}) {}
}

Future<void> _post(String path) async {
  final http = HttpClient();
  final req = await http.postUrl(Uri.parse('$_url$path'));
  await (await req.close()).drain<void>();
  http.close();
}

void main() {
  final skip = _url == null ? 'defina MOCK_SERVER_URL' : null;

  test('GET /v1/config do mock vira AppConfig', () async {
    final api = ApiClient(
      apiBaseUrl: _url!,
      appVersion: '0.1.0',
      language: () => 'pt-BR',
      onGate: (_) {},
    );
    await _post('/__mock/reset');
    final json = await api.call((d) => d.get<Map<String, dynamic>>('/config'));
    final c = AppConfigDto.fromJson(json).toEntity();
    expect(c.isEnabled('pk'), isTrue);
    expect(c.limits['chatMaxLength'], 200);
  }, skip: skip);

  test('RealtimeClient autentica e recebe config.updated do cenário', () async {
    final client = RealtimeClient(
      uri: Uri.parse('${_url!.replaceFirst('http', 'ws')}/v1/realtime'),
      tokens: _Dev(),
    );
    final connected = client.statusChanges.firstWhere(
      (s) => s == RealtimeStatus.connected,
    );
    await client.start();
    await connected.timeout(const Duration(seconds: 5));
    final updated = client.on('config.updated').first;
    final http = HttpClient();
    final req = await http.postUrl(
      Uri.parse('$_url/__mock/scenario/manutencao'),
    );
    await (await req.close()).drain<void>();
    final ev = await updated.timeout(const Duration(seconds: 5));
    expect(ev.data['maintenance'], {'active': true, 'retryAfterSeconds': 300});
    final reset = await http.postUrl(Uri.parse('$_url/__mock/reset'));
    await (await reset.close()).drain<void>();
    http.close();
    await client.dispose();
  }, skip: skip);
}

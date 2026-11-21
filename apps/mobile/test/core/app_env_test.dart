import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/env/app_env.dart';

void main() {
  test('realtimeUri troca http por ws e https por wss', () {
    expect(
      const AppEnv(
        apiBaseUrl: 'http://localhost:3000',
        appVersion: '0.1.0',
      ).realtimeUri.toString(),
      'ws://localhost:3000/v1/realtime',
    );
    expect(
      const AppEnv(
        apiBaseUrl: 'https://api.exemplo.com',
        appVersion: '0.1.0',
      ).realtimeUri.toString(),
      'wss://api.exemplo.com/v1/realtime',
    );
  });
}

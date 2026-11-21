import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/config/data/key_value_store.dart';
import 'package:livezz_mobile/core/device/device_registrar.dart';
import 'package:livezz_mobile/core/http/api_client.dart';

import '../../helpers/harness.dart';

void main() {
  test('registra, guarda o id do servidor e reenvia nas próximas', () async {
    final bodies = <Object?>[];
    var next = 'srv-1';
    final adapter = StubAdapter((RequestOptions o) {
      bodies.add(o.data);
      return jsonBody(201, {'deviceId': next});
    });
    final store = MemoryStore();
    final reg = DeviceRegistrar(
      ApiClient(
        apiBaseUrl: 'http://x',
        appVersion: '0.1.0',
        language: () => 'pt-BR',
        onGate: (_) {},
        adapter: adapter,
      ),
      store,
    );
    expect(
      await reg.register(platform: 'web', appVersion: '0.1.0', locale: 'pt-BR'),
      'srv-1',
    );
    expect(bodies.single, {
      'platform': 'web',
      'appVersion': '0.1.0',
      'locale': 'pt-BR',
    });
    next = 'srv-2'; // servidor não reconheceu e gerou outro
    expect(
      await reg.register(platform: 'web', appVersion: '0.1.0', locale: 'pt-BR'),
      'srv-2',
    );
    expect((bodies.last! as Map)['deviceId'], 'srv-1');
    expect(await reg.storedId(), 'srv-2');
  });
}

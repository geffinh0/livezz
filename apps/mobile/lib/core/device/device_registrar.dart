import 'package:dio/dio.dart';

import '../auth/auth_api.dart';
import '../auth/secure_store.dart';
import '../http/api_client.dart';

/// Registra o aparelho (`POST /v1/devices`, ENT01) e guarda id + segredo no
/// armazenamento seguro (ADR 0012). Id e segredo vêm sempre do servidor.
class DeviceRegistrar {
  DeviceRegistrar(this._api, this._store);

  static const _kId = 'device.id';
  static const _kSecret = 'device.secret';
  final ApiClient _api;
  final SecureStore _store;

  Future<String?> storedId() => _store.read(_kId);

  Future<DeviceCredentials?> stored() async {
    final id = await _store.read(_kId);
    final secret = await _store.read(_kSecret);
    return id == null || secret == null
        ? null
        : DeviceCredentials(id: id, secret: secret);
  }

  Future<DeviceCredentials> register({
    required String platform,
    required String appVersion,
    required String locale,
    Map<String, String>? antibot,
  }) async {
    final known = await stored();
    final json = await _api.call(
      (d) => d.post<Map<String, dynamic>>(
        '/devices',
        data: {
          ...?known?.toJson(),
          'platform': platform,
          'appVersion': appVersion,
          'locale': locale,
        },
        options: antibot == null ? null : Options(headers: antibot),
      ),
    );
    final id = json['deviceId'] as String;
    final secret = json['deviceSecret'] as String? ?? known?.secret;
    if (secret == null) throw StateError('servidor não devolveu o segredo');
    await _store.write(_kId, id);
    await _store.write(_kSecret, secret);
    return DeviceCredentials(id: id, secret: secret);
  }
}

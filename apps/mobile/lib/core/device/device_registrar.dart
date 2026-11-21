import '../config/data/key_value_store.dart';
import '../http/api_client.dart';

/// Registra o aparelho no servidor (`POST /v1/devices`, ENT01) e guarda o id
/// devolvido. O id é sempre do servidor: id desconhecido recebe um novo.
class DeviceRegistrar {
  DeviceRegistrar(this._api, this._store);

  static const _key = 'device.id';
  final ApiClient _api;
  final KeyValueStore _store;

  Future<String?> storedId() => _store.read(_key);

  Future<String> register({
    required String platform,
    required String appVersion,
    required String locale,
  }) async {
    final known = await _store.read(_key);
    final json = await _api.call(
      (d) => d.post<Map<String, dynamic>>(
        '/devices',
        data: {
          'deviceId': ?known,
          'platform': platform,
          'appVersion': appVersion,
          'locale': locale,
        },
      ),
    );
    final id = json['deviceId'] as String;
    if (id != known) await _store.write(_key, id);
    return id;
  }
}

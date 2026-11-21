import 'dart:convert';

import '../../http/api_client.dart';
import '../domain/app_config.dart';
import 'app_config_dto.dart';
import 'key_value_store.dart';

/// Busca a config no servidor e guarda a última válida como cache (TRV04).
class ConfigRepository {
  ConfigRepository(this._api, this._store);

  static const _cacheKey = 'config.lastValid.v1';
  final ApiClient _api;
  final KeyValueStore _store;
  Map<String, dynamic>? _lastJson;

  Future<AppConfig> fetch() async {
    final json = await _api.call((d) => d.get<Map<String, dynamic>>('/config'));
    final config = AppConfigDto.fromJson(json).toEntity();
    // `region` é por requisição: nunca vai para o cache nem para a mesclagem.
    final cacheable = Map<String, dynamic>.of(json)..remove('region');
    _lastJson = cacheable;
    await _store.write(_cacheKey, jsonEncode(cacheable));
    return config;
  }

  /// Última config válida guardada (usada sem rede).
  Future<AppConfig?> cached() async {
    final raw = await _store.read(_cacheKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final config = AppConfigDto.fromJson(json).toEntity();
      _lastJson = json;
      return config;
    } on Object {
      return null; // cache corrompido: ignora
    }
  }

  /// Aplica `config.updated`. Retorna null se não houver base para mesclar.
  Future<AppConfig?> applyPartial(Map<String, dynamic> partial) async {
    final base = _lastJson;
    if (base == null) return null;
    final merged = mergeConfigJson(base, partial)..remove('region');
    final config = AppConfigDto.fromJson(merged).toEntity();
    _lastJson = merged;
    await _store.write(_cacheKey, jsonEncode(merged));
    return config;
  }
}

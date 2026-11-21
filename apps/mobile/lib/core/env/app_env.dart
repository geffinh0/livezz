import '../tenant/tenant_config.dart';

/// Ambiente de execução. A URL da API vem de `--dart-define=API_BASE_URL=...`
/// e, se ausente, do padrão do tenant (revisão do arquiteto, item 1).
class AppEnv {
  const AppEnv({required this.apiBaseUrl, required this.appVersion});

  factory AppEnv.from(TenantConfig tenant) {
    const override = String.fromEnvironment('API_BASE_URL');
    const version = String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '0.1.0',
    );
    return AppEnv(
      apiBaseUrl: override.isEmpty ? tenant.defaultApiBaseUrl : override,
      appVersion: version,
    );
  }

  final String apiBaseUrl;
  final String appVersion;

  /// `http(s)://host:porta` → `ws(s)://host:porta/v1/realtime`.
  Uri get realtimeUri {
    final base = Uri.parse(apiBaseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/v1/realtime',
    );
  }
}

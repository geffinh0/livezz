import 'dart:ui';

/// Marca do tenant (white-label). Gerada de `tenants/<id>/tenant.json` por
/// `tools/tenant/generate.mjs`. Só marca, cores e URLs: flags vêm do servidor.
class TenantConfig {
  const TenantConfig({
    required this.id,
    required this.appName,
    required this.defaultApiBaseUrl,
    required this.portalBaseUrl,
    required this.defaultLocale,
    required this.supportedLocales,
    required this.themeModes,
    required this.fontFamily,
    required this.colors,
  });

  final String id;
  final String appName;
  final String defaultApiBaseUrl;
  final String portalBaseUrl;
  final String defaultLocale;
  final List<String> supportedLocales;
  final List<String> themeModes;
  final String fontFamily;
  final TenantColors colors;
}

class TenantColors {
  const TenantColors({
    required this.primary,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.secondary,
    required this.onSecondary,
    required this.darkBackground,
    required this.lightBackground,
  });

  final Color primary;
  final Color primaryAction;
  final Color onPrimaryAction;
  final Color secondary;
  final Color onSecondary;
  final Color darkBackground;
  final Color lightBackground;
}

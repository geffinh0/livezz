import 'dart:ui';

/// Converte os idiomas do tenant (`pt-BR`, `en`) nos locales dos arquivos ARB.
Locale localeFromTag(String tag) {
  final parts = tag.split('-');
  return Locale(parts.first);
}

/// CFG14: na primeira vez, segue o idioma do aparelho. Português → pt-BR;
/// qualquer outro → inglês (se o tenant oferecer); senão, o padrão do tenant.
Locale initialLocale(Locale device, List<String> supported, String fallback) {
  final codes = supported.map((t) => localeFromTag(t).languageCode).toSet();
  if (device.languageCode == 'pt' && codes.contains('pt')) {
    return const Locale('pt');
  }
  if (device.languageCode != 'pt' && codes.contains('en')) {
    return const Locale('en');
  }
  return localeFromTag(fallback);
}

/// Header `Accept-Language` enviado à API (contrato: `pt-BR` ou `en`).
String acceptLanguageFor(Locale locale) =>
    locale.languageCode == 'en' ? 'en' : 'pt-BR';

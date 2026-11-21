import 'dart:ui';

/// Converte os idiomas do tenant (`pt-BR`, `en`) nos locales dos arquivos ARB.
Locale localeFromTag(String tag) {
  final parts = tag.split('-');
  return Locale(parts.first);
}

/// Header `Accept-Language` enviado à API (contrato: `pt-BR` ou `en`).
String acceptLanguageFor(Locale locale) =>
    locale.languageCode == 'en' ? 'en' : 'pt-BR';

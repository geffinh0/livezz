import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/l10n/error_messages.dart';
import 'package:livezz_mobile/l10n/generated/app_localizations_en.dart';
import 'package:livezz_mobile/l10n/generated/app_localizations_pt.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

List<String> _apiErrorCatalog() {
  final md = File('../../docs/API.md').readAsStringSync();
  final start = md.indexOf('## Catálogo de erros');
  final section = md.substring(start, md.indexOf('## Endpoints'));
  return RegExp('`([a-z_]+)`')
      .allMatches(section)
      .map((m) => m.group(1)!)
      .toList();
}

void main() {
  test('pt e en têm exatamente as mesmas chaves', () {
    Set<String> keys(Map<String, dynamic> m) =>
        m.keys.where((k) => !k.startsWith('@')).toSet();
    expect(keys(_arb('app_en.arb')), keys(_arb('app_pt.arb')));
  });

  test('todo código do catálogo da API tem texto em pt e en', () {
    final catalog = _apiErrorCatalog();
    expect(catalog, isNotEmpty);
    expect(knownErrorCodes.toSet(), catalog.toSet());
    final pt = AppLocalizationsPt();
    final en = AppLocalizationsEn();
    for (final code in catalog) {
      expect(errorMessageFor(pt, code), isNot(pt.errorUnknown), reason: code);
      expect(errorMessageFor(en, code), isNot(en.errorUnknown), reason: code);
    }
  });

  test('código desconhecido cai no texto genérico', () {
    final pt = AppLocalizationsPt();
    expect(errorMessageFor(pt, 'inventado'), pt.errorUnknown);
  });
}

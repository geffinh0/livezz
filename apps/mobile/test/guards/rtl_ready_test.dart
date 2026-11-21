import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regra de RTL (DESIGN-SYSTEM §6): só propriedades direcionais (start/end).
final _forbidden = <RegExp>[
  RegExp(r'EdgeInsets\.only\([^)]*\b(left|right):'),
  RegExp(r'EdgeInsets\.fromLTRB\('),
  RegExp(
    r'Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)',
  ),
  RegExp(r'Positioned\([^)]*\b(left|right):'),
  RegExp(
    r'BorderRadius\.only\([^)]*\b(topLeft|topRight|bottomLeft|bottomRight):',
  ),
  RegExp(r'TextAlign\.(left|right)'),
];

void main() {
  test('lib/ não usa left/right fixos', () {
    final hits = <String>[];
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('/generated/')) continue;
      final src = f.readAsStringSync();
      for (final r in _forbidden) {
        for (final m in r.allMatches(src)) {
          hits.add('${f.path}: ${m.group(0)}');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/config/data/key_value_store.dart';
import 'package:livezz_mobile/features/entry/data/entry_prefs.dart';

void main() {
  test('modo visitante começa desligado e persiste', () async {
    final prefs = EntryPrefs(MemoryStore());
    expect(await prefs.visitorMode(), isFalse);
    await prefs.setVisitorMode(on: true);
    expect(await prefs.visitorMode(), isTrue);
  });
}

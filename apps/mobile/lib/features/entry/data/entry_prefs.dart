import '../../../core/config/data/key_value_store.dart';

/// Preferências locais da entrada (PreferenciasLocais no DATABASE.md).
class EntryPrefs {
  EntryPrefs(this._store);
  static const _visitor = 'entry.visitorMode';
  final KeyValueStore _store;

  Future<bool> visitorMode() async => await _store.read(_visitor) == '1';
  Future<void> setVisitorMode({required bool on}) =>
      _store.write(_visitor, on ? '1' : '0');
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regra: SDK de vídeo real só em lib/core/video/providers/agora/ (e o
/// video_player do fake só em providers/fake/).
void main() {
  test('SDKs de vídeo só dentro dos seus providers', () {
    final hits = <String>[];
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      if (src.contains('package:agora_') &&
          !f.path.contains('lib/core/video/providers/agora/')) {
        hits.add(f.path);
      }
      if (src.contains('package:video_player/') &&
          !f.path.contains('lib/core/video/providers/fake/')) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}

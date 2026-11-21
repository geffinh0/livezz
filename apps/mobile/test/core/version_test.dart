import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/env/version.dart';

void main() {
  test('compara versões x.y.z', () {
    expect(compareVersions('0.1.0', '0.1.0'), 0);
    expect(compareVersions('0.1.0', '99.0.0'), lessThan(0));
    expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
    expect(compareVersions('2', '1.9'), greaterThan(0));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/features/entry/presentation/legal_screen.dart';

void main() {
  final portal = Uri.parse('https://portal.cliente.com');
  test('só libera o domínio do portal (inclusive a primeira URL)', () {
    expect(
      isAllowedLegalUrl(
        Uri.parse('https://portal.cliente.com/legal/termos'),
        portal,
      ),
      isTrue,
    );
    expect(
      isAllowedLegalUrl(Uri.parse('http://portal.cliente.com/legal'), portal),
      isFalse,
    );
    expect(
      isAllowedLegalUrl(Uri.parse('https://evil.com/legal'), portal),
      isFalse,
    );
    expect(
      isAllowedLegalUrl(
        Uri.parse('https://portal.cliente.com.evil.com/'),
        portal,
      ),
      isFalse,
    );
    expect(isAllowedLegalUrl(Uri.tryParse('::not a url'), portal), isFalse);
    expect(isAllowedLegalUrl(null, portal), isFalse);
  });
}

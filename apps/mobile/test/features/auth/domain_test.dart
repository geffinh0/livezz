import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/features/auth/domain/password_rules.dart';
import 'package:livezz_mobile/features/auth/domain/phone.dart';

void main() {
  const br = Country('BR', '55', '(##) #####-####');

  test('máscara do Brasil e E.164', () {
    expect(applyMask('11912345678', br.mask), '(11) 91234-5678');
    expect(applyMask('119', br.mask), '(11) 9');
    expect(applyMask('11912345678999', br.mask), '(11) 91234-5678');
    expect(toE164(br, '(11) 91234-5678'), '+5511912345678');
    expect(toE164(br, '(11) 9123'), isNull);
  });

  test('países vêm de allowedRegions', () {
    expect(countriesFor(['BR']).map((c) => c.iso), ['BR']);
    expect(countriesFor(['XX']), isEmpty);
  });

  test('telefone mascarado para exibir', () {
    expect(maskForDisplay('+5511912345678'), '+55 •••••-5678');
  });

  test('regras de senha (ajuda local, RN-03)', () {
    expect(passwordProblems('abc'), {
      PasswordRule.minLength,
      PasswordRule.numbers,
    });
    expect(passwordProblems('Livezz2026'), isEmpty);
    expect(rulesFromServer(['common']), {PasswordRule.common});
  });

  test('e-mail', () {
    expect(looksLikeEmail('a@b.com'), isTrue);
    expect(looksLikeEmail('a@b'), isFalse);
  });
}

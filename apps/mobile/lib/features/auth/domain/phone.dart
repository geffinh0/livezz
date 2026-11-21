/// Telefone (ENT04): país, máscara e E.164. Dart puro.
class Country {
  const Country(this.iso, this.dialCode, this.mask);
  final String iso;
  final String dialCode;

  /// `#` = dígito. Ex.: Brasil `(##) #####-####`.
  final String mask;

  int get digits => '#'.allMatches(mask).length;
}

/// Países suportados pela máscara. A lista exibida é filtrada por
/// `allowedRegions` (config do servidor).
const knownCountries = <Country>[
  Country('BR', '55', '(##) #####-####'),
  Country('PT', '351', '### ### ###'),
  Country('US', '1', '(###) ###-####'),
];

List<Country> countriesFor(List<String> allowedRegions) => [
  for (final c in knownCountries)
    if (allowedRegions.contains(c.iso)) c,
];

String onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Aplica a máscara aos dígitos digitados (ignora o excesso).
String applyMask(String digits, String mask) {
  final d = onlyDigits(digits);
  final out = StringBuffer();
  var i = 0;
  for (final ch in mask.split('')) {
    if (i >= d.length) break;
    if (ch == '#') {
      out.write(d[i++]);
    } else {
      out.write(ch);
    }
  }
  return out.toString();
}

/// E.164 completo quando o número tem todos os dígitos; senão null.
String? toE164(Country c, String input) {
  final d = onlyDigits(input);
  return d.length == c.digits ? '+${c.dialCode}$d' : null;
}

/// Mostra o telefone mascarado para confirmar sem expor tudo: `+55 •••••-4321`.
String maskForDisplay(String e164) {
  if (e164.length < 6) return e164;
  return '${e164.substring(0, 3)} •••••-${e164.substring(e164.length - 4)}';
}

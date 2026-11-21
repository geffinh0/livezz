/// RN-03 no app só como ajuda ao digitar; quem decide é o servidor
/// (`400 validacao` com `details.rules`).
enum PasswordRule { minLength, letters, numbers, common }

Set<PasswordRule> passwordProblems(String p) => {
  if (p.length < 8) PasswordRule.minLength,
  if (!RegExp('[A-Za-z]').hasMatch(p)) PasswordRule.letters,
  if (!RegExp(r'\d').hasMatch(p)) PasswordRule.numbers,
};

/// Converte os códigos do servidor (`min_length`, `letters`…) nas regras.
Set<PasswordRule> rulesFromServer(Object? rules) => {
  if (rules is List)
    for (final r in rules)
      switch (r) {
        'min_length' => PasswordRule.minLength,
        'letters' => PasswordRule.letters,
        'numbers' => PasswordRule.numbers,
        _ => PasswordRule.common,
      },
};

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
bool looksLikeEmail(String s) => _email.hasMatch(s.trim());

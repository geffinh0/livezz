/// Caminhos das rotas (go_router). Deep links usam os mesmos caminhos.
abstract final class Routes {
  static const start = '/';
  static const gate = '/gate';
  static const welcome = '/welcome';
  static const entry = '/entry';
  static const entrySignup = '/entry?mode=signup';
  static String entryMethod(String method) => '/entry/method/$method';
  static String legal(String doc) => '/legal/$doc';
  static const entryReset = '/entry/reset';

  /// Dados vão em `extra` (CodeArgs): telefone e e-mail nunca na URL.
  static const entryCode = '/entry/code';
  static const terms = '/terms';
  static const onboardingProfile = '/onboarding/profile';
  static const onboardingUsername = '/onboarding/username';
  static const onboardingInterests = '/onboarding/interests';
  static const minorBlocked = '/blocked';
  static const settings = '/settings';
  static const discover = '/discover';
  static const following = '/following';
  static const live = '/live';
  static const messages = '/messages';
  static const profile = '/profile';
  static const devShowcase = '/dev/showcase';
}

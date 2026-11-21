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
  static String entryCode({
    required String destination,
    required String channel,
    required String purpose,
  }) => Uri(
    path: '/entry/code',
    queryParameters: {
      'dest': destination,
      'channel': channel,
      'purpose': purpose,
    },
  ).toString();
  static const terms = '/terms';
  static const completeProfile = '/complete-profile';
  static const discover = '/discover';
  static const following = '/following';
  static const live = '/live';
  static const messages = '/messages';
  static const profile = '/profile';
  static const devShowcase = '/dev/showcase';
}

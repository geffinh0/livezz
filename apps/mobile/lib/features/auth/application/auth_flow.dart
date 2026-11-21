import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/antibot/antibot_provider.dart';
import '../../../core/auth/auth_api.dart';
import '../../../core/auth/session.dart';
import '../../../core/errors/app_failure.dart';
import '../../entry/application/entry_providers.dart';

final antiBotProvider = Provider<AntiBotProvider>(
  (ref) => const FakeAntiBotProvider(),
);

/// Orquestra os logins (ENT04–ENT07): anti-bot quando o servidor pede (428),
/// credenciais do aparelho e entrada na sessão.
class AuthFlow {
  AuthFlow(this._ref);
  final Ref _ref;

  AuthApi get _api => _ref.read(authApiProvider);

  /// Roda [call]; se o servidor exigir desafio, resolve e tenta uma vez mais.
  Future<T> _withAntiBot<T>(Future<T> Function(AntiBotHeaders? h) call) async {
    try {
      return await call(null);
    } on ApiFailure catch (e) {
      if (e.code != 'desafio_necessario') rethrow;
      final providers =
          (e.details['providers'] as List?)?.cast<String>() ?? const [];
      final headers = await _ref.read(antiBotProvider).solve(providers);
      if (headers == null) rethrow;
      return call(headers);
    }
  }

  Future<DeviceCredentials> _device() async {
    final d = await _ref.read(deviceCredentialsProvider.future);
    if (d == null) throw const NetworkFailure();
    return d;
  }

  Future<({int expiresIn, int resendIn})> sendCode({
    required String channel,
    required String destination,
    required String purpose,
  }) => _withAntiBot(
    (h) => _api.sendCode(
      channel: channel,
      destination: destination,
      purpose: purpose,
      antibot: h,
    ),
  );

  Future<void> verifyCode({
    required String destination,
    required String code,
    required String purpose,
  }) async {
    final t = await _api.verifyCode(
      destination: destination,
      code: code,
      purpose: purpose,
      device: await _device(),
    );
    await _ref.read(sessionProvider.notifier).signedIn(t);
  }

  Future<void> signupEmail(String email, String password) =>
      _withAntiBot((h) => _api.signupEmail(email, password, antibot: h));

  Future<void> loginEmail(String email, String password) async {
    final device = await _device();
    final t = await _withAntiBot(
      (h) => _api.loginEmail(email, password, device, antibot: h),
    );
    await _ref.read(sessionProvider.notifier).signedIn(t);
  }

  Future<void> google(String idToken) async {
    final t = await _api.google(idToken, await _device());
    await _ref.read(sessionProvider.notifier).signedIn(t);
  }

  Future<void> resetPassword(String email, String code, String newPassword) =>
      _withAntiBot(
        (h) => _api.resetPassword(
          email: email,
          code: code,
          newPassword: newPassword,
          antibot: h,
        ),
      );

  Future<void> acceptTerms(List<PendingTerm> terms) async {
    for (final t in terms) {
      await _api.acceptTerms(t.document, t.version);
    }
    await _ref.read(sessionProvider.notifier).reloadMe();
  }
}

final authFlowProvider = Provider<AuthFlow>(AuthFlow.new);

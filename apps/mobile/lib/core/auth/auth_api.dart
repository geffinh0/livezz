import 'package:dio/dio.dart';

import '../http/api_client.dart';

/// Credenciais do aparelho (ADR 0012): exigidas no login e no refresh.
class DeviceCredentials {
  const DeviceCredentials({required this.id, required this.secret});
  final String id;
  final String secret;
  Map<String, String> toJson() => {'deviceId': id, 'deviceSecret': secret};
}

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.needsProfile,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>;
    return TokenResponse(
      accessToken: j['accessToken'] as String,
      refreshToken: j['refreshToken'] as String,
      userId: user['id'] as String,
      needsProfile: user['needsProfile'] as bool,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String userId;
  final bool needsProfile;
}

class PendingTerm {
  const PendingTerm({
    required this.document,
    required this.version,
    required this.url,
  });
  final String document;
  final int version;
  final Uri url;
}

class Me {
  const Me({
    required this.id,
    required this.needsProfile,
    required this.pendingTerms,
  });

  factory Me.fromJson(Map<String, dynamic> j) => Me(
    id: j['id'] as String,
    needsProfile: j['needsProfile'] as bool,
    pendingTerms: [
      for (final t in (j['pendingTerms'] as List).cast<Map<String, dynamic>>())
        PendingTerm(
          document: t['document'] as String,
          version: t['version'] as int,
          url: Uri.parse(t['url'] as String),
        ),
    ],
  );

  final String id;
  final bool needsProfile;
  final List<PendingTerm> pendingTerms;
}

/// Anti-bot (SEG06): headers do desafio quando o servidor pediu (428).
typedef AntiBotHeaders = Map<String, String>;

/// Chamadas de autenticação (docs/API.md, Fase 1b).
class AuthApi {
  AuthApi(this._api);
  final ApiClient _api;

  Options _opts([AntiBotHeaders? antibot, bool auth = false]) =>
      Options(headers: antibot, extra: auth ? null : {noAuthExtra: true});

  Future<({int expiresIn, int resendIn})> sendCode({
    required String channel,
    required String destination,
    required String purpose,
    AntiBotHeaders? antibot,
  }) async {
    final j = await _api.call(
      (d) => d.post<Map<String, dynamic>>(
        '/auth/code/send',
        data: {
          'channel': channel,
          'destination': destination,
          'purpose': purpose,
        },
        options: _opts(antibot),
      ),
    );
    return (
      expiresIn: j['expiresInSeconds'] as int,
      resendIn: j['resendInSeconds'] as int,
    );
  }

  Future<TokenResponse> verifyCode({
    required String destination,
    required String code,
    required String purpose,
    required DeviceCredentials device,
    String? password,
  }) async => TokenResponse.fromJson(
    await _api.call(
      (d) => d.post<Map<String, dynamic>>(
        '/auth/code/verify',
        data: {
          'destination': destination,
          'code': code,
          'purpose': purpose,
          'password': ?password,
          ...device.toJson(),
        },
        options: _opts(),
      ),
    ),
  );

  Future<({int expiresIn, int resendIn})> signupEmail(
    String email,
    String password, {
    AntiBotHeaders? antibot,
  }) async {
    final j = await _api.call(
      (d) => d.post<Map<String, dynamic>>(
        '/auth/email/signup',
        data: {'email': email, 'password': password},
        options: _opts(antibot),
      ),
    );
    return (
      expiresIn: j['expiresInSeconds'] as int,
      resendIn: j['resendInSeconds'] as int,
    );
  }

  Future<TokenResponse> loginEmail(
    String email,
    String password,
    DeviceCredentials device, {
    AntiBotHeaders? antibot,
  }) async => TokenResponse.fromJson(
    await _api.call(
      (d) => d.post<Map<String, dynamic>>(
        '/auth/email/login',
        data: {'email': email, 'password': password, ...device.toJson()},
        options: _opts(antibot),
      ),
    ),
  );

  Future<TokenResponse> google(
    String idToken,
    DeviceCredentials device,
  ) async => TokenResponse.fromJson(
    await _api.call(
      (d) => d.post<Map<String, dynamic>>(
        '/auth/google',
        data: {'idToken': idToken, ...device.toJson()},
        options: _opts(),
      ),
    ),
  );

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    AntiBotHeaders? antibot,
  }) => _api.call(
    (d) => d.post<Object?>(
      '/auth/password/reset',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
      options: _opts(antibot),
    ),
  );

  Future<TokenResponse> refresh(
    String refreshToken,
    DeviceCredentials device,
  ) async => TokenResponse.fromJson(
    await _api.call(
      (d) => d.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken, ...device.toJson()},
        options: _opts(),
      ),
    ),
  );

  Future<void> logout({String? accessToken, String? refreshToken}) => _api.call(
    (d) => d.post<Object?>(
      '/auth/logout',
      data: {'refreshToken': ?refreshToken},
      options: Options(
        headers: {
          'Authorization': ?(accessToken == null
              ? null
              : 'Bearer $accessToken'),
        },
        extra: {noAuthExtra: true},
      ),
    ),
  );

  Future<Me> me() async => Me.fromJson(
    await _api.call(
      (d) => d.get<Map<String, dynamic>>('/me', options: _opts(null, true)),
    ),
  );

  Future<void> acceptTerms(String document, int version) => _api.call(
    (d) => d.post<Object?>(
      '/me/terms/accept',
      data: {'document': document, 'version': version},
      options: _opts(null, true),
    ),
  );
}

import '../../../core/age/age_signal_provider.dart';
import '../../../core/http/api_client.dart';

/// Resultado da consulta de @ (ENT11).
class UsernameCheck {
  const UsernameCheck({
    required this.available,
    this.reason,
    this.suggestions = const [],
  });

  factory UsernameCheck.fromJson(Map<String, dynamic> j) => UsernameCheck(
    available: j['available'] as bool,
    reason: j['reason'] as String?,
    suggestions: (j['suggestions'] as List? ?? const []).cast<String>(),
  );

  final bool available;

  /// `formato`, `ocupado`, `reservado`.
  final String? reason;
  final List<String> suggestions;
}

class Interest {
  const Interest({required this.id, required this.name});
  final String id;
  final String name;
}

/// Cadastro inicial (docs/API.md "Cadastro inicial"): ENT08, ENT11, ENT12, CFG14.
class ProfileApi {
  ProfileApi(this._api);
  final ApiClient _api;

  Future<void> saveProfile({
    required String displayName,
    required String birthDate,
    String? gender,
    String? language,
    AgeSignal? storeAgeSignal,
  }) => _api.call(
    (d) => d.patch<Object?>(
      '/me',
      data: {
        'displayName': displayName,
        'birthDate': birthDate,
        'gender': gender,
        'language': ?language,
        if (storeAgeSignal != null) 'storeAgeSignal': storeAgeSignal.toJson(),
      },
    ),
  );

  Future<void> saveLanguage(String language) =>
      _api.call((d) => d.patch<Object?>('/me', data: {'language': language}));

  Future<UsernameCheck> checkUsername(String username) async =>
      UsernameCheck.fromJson(
        await _api.call(
          (d) => d.get<Map<String, dynamic>>(
            '/usernames/${Uri.encodeComponent(username)}/availability',
          ),
        ),
      );

  Future<void> setUsername(String username) => _api.call(
    (d) => d.post<Object?>('/me/username', data: {'username': username}),
  );

  Future<List<Interest>> interests() async {
    final j = await _api.call((d) => d.get<Map<String, dynamic>>('/interests'));
    return [
      for (final i in (j['items'] as List).cast<Map<String, dynamic>>())
        Interest(id: i['id'] as String, name: i['name'] as String),
    ];
  }

  Future<void> setInterests(List<String> ids) =>
      _api.call((d) => d.post<Object?>('/me/interests', data: {'ids': ids}));
}

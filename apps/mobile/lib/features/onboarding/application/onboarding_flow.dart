import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show Locale;

import '../../../app/providers.dart';
import '../../../core/age/age_signal_provider.dart';
import '../../../core/auth/session.dart';
import '../../../core/i18n/locales.dart';
import '../data/profile_api.dart';

/// Sinal de idade da loja (Q-64): fake até a Fase 12.
final ageSignalProviderProvider = Provider<AgeSignalProvider>(
  (ref) => const FakeAgeSignalProvider(),
);

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(apiClientProvider)),
);

/// Orquestra o cadastro inicial (plano 1c). Depois de cada passo recarrega o
/// `/me`: o roteador segue para o próximo passo que o servidor disser.
class OnboardingFlow {
  OnboardingFlow(this._ref);
  final Ref _ref;

  ProfileApi get _api => _ref.read(profileApiProvider);
  Future<void> _reload() => _ref.read(sessionProvider.notifier).reloadMe();

  Future<AgeSignal> _signal() async {
    try {
      return await _ref.read(ageSignalProviderProvider).read();
    } on Object catch (e) {
      // Sem loja, sem Play Services ou erro: segue só com a data.
      developer.log('sinal de idade indisponível: $e', name: 'age');
      return const AgeSignal.unavailable();
    }
  }

  /// ENT08. Menor → o servidor responde `menor_de_idade` e o app vai para ENT10.
  Future<void> saveProfile({
    required String displayName,
    required DateTime birthDate,
    String? gender,
  }) async {
    final d = birthDate;
    final iso =
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    await _api.saveProfile(
      displayName: displayName,
      birthDate: iso,
      gender: gender,
      // A conta nova fica com o idioma que a pessoa está usando (CFG14).
      language: acceptLanguageFor(_ref.read(localeProvider)),
      storeAgeSignal: await _signal(),
    );
    await _reload();
  }

  Future<UsernameCheck> checkUsername(String u) => _api.checkUsername(u);

  Future<void> setUsername(String u) async {
    await _api.setUsername(u);
    await _reload();
  }

  Future<List<Interest>> interests() => _api.interests();

  /// CFG14: troca o idioma na hora; com conta, avisa o servidor (textos e push).
  Future<void> changeLanguage(Locale locale) async {
    await _ref.read(localeProvider.notifier).set(locale);
    if (_ref.read(sessionProvider) == null) return;
    final store = _ref.read(keyValueStoreProvider);
    try {
      await _api.saveLanguage(acceptLanguageFor(locale));
      await store.write(_pendingKey, '');
    } on Object {
      // Fica pendente: reenviado na próxima abertura com conta.
      await store.write(_pendingKey, acceptLanguageFor(locale));
      rethrow;
    }
  }

  static const _pendingKey = 'app.language.pendingSync';

  /// Ao entrar numa conta (CFG14): troca que não chegou ao servidor é
  /// reenviada (vale a do aparelho); senão, vale o idioma da conta.
  Future<void> onAccountLanguage(String? accountLanguage) async {
    final store = _ref.read(keyValueStoreProvider);
    try {
      final pending = await store.read(_pendingKey);
      if (pending != null && pending.isNotEmpty) {
        await _api.saveLanguage(pending);
        await store.write(_pendingKey, '');
        return;
      }
      if (accountLanguage != null) {
        await _ref
            .read(localeProvider.notifier)
            .set(localeFromTag(accountLanguage));
      }
    } on Object catch (e) {
      developer.log('idioma da conta não sincronizou: $e', name: 'i18n');
    }
  }

  /// ENT12: lista vazia = pulou.
  Future<void> setInterests(List<String> ids) async {
    await _api.setInterests(ids);
    await _reload();
  }
}

final onboardingFlowProvider = Provider<OnboardingFlow>(OnboardingFlow.new);

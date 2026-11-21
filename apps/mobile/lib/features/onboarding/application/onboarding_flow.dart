import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/age/age_signal_provider.dart';
import '../../../core/auth/session.dart';
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

  /// ENT12: lista vazia = pulou.
  Future<void> setInterests(List<String> ids) async {
    await _api.setInterests(ids);
    await _reload();
  }
}

final onboardingFlowProvider = Provider<OnboardingFlow>(OnboardingFlow.new);

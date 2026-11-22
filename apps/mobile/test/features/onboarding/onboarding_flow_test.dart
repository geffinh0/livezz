import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/app/providers.dart';
import 'package:livezz_mobile/core/age/age_signal_provider.dart';
import 'package:livezz_mobile/core/auth/session.dart';
import 'package:livezz_mobile/core/config/data/key_value_store.dart';
import 'package:livezz_mobile/core/errors/app_failure.dart';
import 'package:livezz_mobile/features/onboarding/application/onboarding_flow.dart';
import 'package:livezz_mobile/features/onboarding/data/profile_api.dart';
import 'package:material_ui/material_ui.dart' show Locale;

/// API falsa: guarda o que o app enviou.
class _Api implements ProfileApi {
  final profiles = <Map<String, Object?>>[];
  final languages = <String>[];
  bool failLanguage = false;

  @override
  Future<void> saveProfile({
    required String displayName,
    required String birthDate,
    String? gender,
    String? language,
    AgeSignal? storeAgeSignal,
  }) async => profiles.add({
    'displayName': displayName,
    'birthDate': birthDate,
    'language': language,
    'signal': storeAgeSignal?.toJson(),
  });

  @override
  Future<void> saveLanguage(String language) async {
    if (failLanguage) throw const NetworkFailure();
    languages.add(language);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _BrokenSignal implements AgeSignalProvider {
  @override
  Future<AgeSignal> read() => throw StateError('sem Play Services');
}

void main() {
  late _Api api;
  late MemoryStore store;

  ProviderContainer make(AgeSignalProvider signal) {
    api = _Api();
    store = MemoryStore();
    final c = ProviderContainer(
      overrides: [
        deviceLocaleProvider.overrideWithValue(const Locale('pt', 'BR')),
        keyValueStoreProvider.overrideWithValue(store),
        profileApiProvider.overrideWithValue(api),
        ageSignalProviderProvider.overrideWithValue(signal),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'ENT08: envia o sinal da loja, a data em AAAA-MM-DD e o idioma em uso',
    () async {
      final c = make(
        const FakeAgeSignalProvider(
          AgeSignal(AgeSignalStatus.shared, ageLower: 18),
        ),
      );
      await c
          .read(onboardingFlowProvider)
          .saveProfile(displayName: 'Ana', birthDate: DateTime(1995, 4, 9));
      expect(api.profiles.single, {
        'displayName': 'Ana',
        'birthDate': '1995-04-09',
        'language': 'pt-BR',
        'signal': {'status': 'shared', 'ageLower': 18, 'ageUpper': null},
      });
    },
  );

  test(
    'ENT08: sinal da loja com erro segue só com a data (indisponível)',
    () async {
      final c = make(_BrokenSignal());
      await c
          .read(onboardingFlowProvider)
          .saveProfile(displayName: 'Ana', birthDate: DateTime(1995));
      expect((api.profiles.single['signal']! as Map)['status'], 'unavailable');
    },
  );

  test(
    'CFG14: troca que falhou no servidor é reenviada ao entrar de novo',
    () async {
      final c = make(const FakeAgeSignalProvider());
      c.read(sessionProvider.notifier).set(const Session(userId: 'u1'));
      api.failLanguage = true;
      await expectLater(
        c.read(onboardingFlowProvider).changeLanguage(const Locale('en')),
        throwsA(isA<NetworkFailure>()),
      );
      expect(c.read(localeProvider), const Locale('en')); // trocou na hora
      api.failLanguage = false;
      await c.read(onboardingFlowProvider).onAccountLanguage('pt-BR');
      expect(api.languages, ['en']); // reenviou a escolha da pessoa
      expect(c.read(localeProvider), const Locale('en'));
      // Sem pendência, vale o idioma da conta.
      await c.read(onboardingFlowProvider).onAccountLanguage('pt-BR');
      expect(c.read(localeProvider), const Locale('pt'));
    },
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/app/providers.dart';
import 'package:livezz_mobile/core/auth/session.dart';
import 'package:livezz_mobile/core/config/data/key_value_store.dart';
import 'package:livezz_mobile/core/i18n/locales.dart';
import 'package:livezz_mobile/features/onboarding/application/onboarding_flow.dart';
import 'package:livezz_mobile/features/onboarding/data/profile_api.dart';
import 'package:livezz_mobile/features/settings/presentation/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/harness.dart';

class _FakeProfileApi implements ProfileApi {
  final saved = <String>[];
  @override
  Future<void> saveLanguage(String language) async => saved.add(language);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  group('idioma inicial (CFG14)', () {
    const tags = ['pt-BR', 'en'];
    test('português do aparelho → pt', () {
      expect(
        initialLocale(const Locale('pt', 'PT'), tags, 'pt-BR'),
        const Locale('pt'),
      );
    });
    test('outro idioma → inglês', () {
      expect(
        initialLocale(const Locale('es'), tags, 'pt-BR'),
        const Locale('en'),
      );
      expect(
        initialLocale(const Locale('en', 'US'), tags, 'pt-BR'),
        const Locale('en'),
      );
    });
    test('tenant só com português → padrão', () {
      expect(
        initialLocale(const Locale('es'), const ['pt-BR'], 'pt-BR'),
        const Locale('pt'),
      );
    });
  });

  test('escolha guardada vale na próxima abertura', () async {
    final store = MemoryStore()..data['app.language'] = 'en';
    final c = ProviderContainer(
      overrides: [
        deviceLocaleProvider.overrideWithValue(const Locale('pt', 'BR')),
        keyValueStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(localeProvider), const Locale('pt'));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(localeProvider), const Locale('en'));
    await c.read(localeProvider.notifier).set(const Locale('pt'));
    expect(store.data['app.language'], 'pt-BR');
  });

  testWidgets(
    'Configurações: troca sem reiniciar e avisa o servidor com conta',
    (t) async {
      final api = _FakeProfileApi();
      final store = MemoryStore();
      await t.pumpWidget(
        Consumer(
          builder: (context, ref, _) => harness(
            const SettingsScreen(),
            overrides: [
              ...testOverrides(
                StubAdapter((o) => jsonBody(200, sampleConfig())),
              ),
              keyValueStoreProvider.overrideWithValue(store),
              profileApiProvider.overrideWithValue(api),
            ],
          ),
        ),
      );
      final c = ProviderScope.containerOf(t.element(find.byType(Scaffold)));
      c.read(sessionProvider.notifier).set(const Session(userId: 'u1'));
      await t.pump();
      expect(find.text('Idioma'), findsOneWidget);
      await t.tap(find.bySemanticsIdentifier('settings.language.en'));
      await t.pump();
      expect(c.read(localeProvider), const Locale('en'));
      expect(api.saved, ['en']);
      expect(store.data['app.language'], 'en');
    },
  );

  testWidgets('Configurações em inglês com fonte 2x não quebra', (t) async {
    await t.pumpWidget(
      harness(
        const SettingsScreen(),
        locale: const Locale('en'),
        textScale: 2,
        overrides: testOverrides(
          StubAdapter((o) => jsonBody(200, sampleConfig())),
        ),
      ),
    );
    await t.pump();
    expect(t.takeException(), isNull);
  });
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth/token_source.dart';
import '../core/config/application/config_controller.dart';
import '../core/config/data/config_repository.dart';
import '../core/config/data/key_value_store.dart';
import '../core/env/app_env.dart';
import '../core/http/api_client.dart';
import '../core/http/app_gate.dart';
import '../core/i18n/locales.dart';
import '../core/realtime/realtime_client.dart';
import '../core/tenant/tenant.generated.dart';
import '../core/tenant/tenant_config.dart';
import '../core/video/providers/fake/fake_video_provider.dart';
import '../core/video/video_provider.dart';

final tenantProvider = Provider<TenantConfig>((ref) => generatedTenant);

final envProvider = Provider<AppEnv>(
  (ref) => AppEnv.from(ref.watch(tenantProvider)),
);

/// Idioma atual (padrão do tenant; troca pelo usuário entra no CFG).
final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => localeFromTag(ref.read(tenantProvider).defaultLocale);
  void set(Locale locale) => state = locale;
}

/// Tema claro/escuro/sistema (CFG08 guarda a escolha na Fase 8).
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void set(ThemeMode mode) => state = mode;
}

/// Portão global (426 → atualizar; 503 manutenção).
final appGateProvider = NotifierProvider<AppGateController, AppGate>(
  AppGateController.new,
);

class AppGateController extends Notifier<AppGate> {
  @override
  AppGate build() => const GateOpen();
  void set(AppGate gate) => state = gate;
}

/// Token de acesso. Fase 0: só em debug, token de teste do mock passado por
/// `--dart-define=MOCK_DEV_TOKEN=dev-token-<usuario>`. Fase 1 troca pela sessão.
final tokenSourceProvider = Provider<TokenSource>((ref) {
  const devToken = String.fromEnvironment('MOCK_DEV_TOKEN');
  if (kDebugMode && devToken.isNotEmpty) return const _DevToken(devToken);
  return const NoTokenSource();
});

class _DevToken implements TokenSource {
  const _DevToken(this.value);
  final String value;
  @override
  Future<String?> accessToken() async => value;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final env = ref.watch(envProvider);
  return ApiClient(
    apiBaseUrl: env.apiBaseUrl,
    appVersion: env.appVersion,
    language: () => acceptLanguageFor(ref.read(localeProvider)),
    onGate: (g) => ref.read(appGateProvider.notifier).set(g),
    tokens: ref.watch(tokenSourceProvider),
  );
});

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => SharedPrefsStore(),
);

/// Sobrescreve o provider abstrato do core com as dependências reais.
final appOverrides = [
  configRepositoryProvider.overrideWith(
    (ref) => ConfigRepository(
      ref.watch(apiClientProvider),
      ref.watch(keyValueStoreProvider),
    ),
  ),
];

/// Tempo real ligado à config: `config.updated` e rebusca ao reconectar.
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(
    uri: ref.watch(envProvider).realtimeUri,
    tokens: ref.watch(tokenSourceProvider),
  );
  final config = ref.read(configControllerProvider.notifier);
  final subs = [
    client.on('config.updated').listen((e) => config.applyRemote(e.data)),
    client.reconnected.listen((_) => config.refresh()),
  ];
  unawaited(client.start());
  ref.onDispose(() async {
    for (final s in subs) {
      await s.cancel();
    }
    await client.dispose();
  });
  return client;
});

final realtimeStatusProvider = StreamProvider<RealtimeStatus>((ref) {
  final client = ref.watch(realtimeClientProvider);
  return client.statusChanges.startWith(client.status);
});

final videoProvider = Provider<VideoProvider>((ref) {
  final v = FakeVideoProvider();
  ref.onDispose(v.dispose);
  return v;
});

extension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}

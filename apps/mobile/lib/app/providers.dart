import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth/auth_api.dart';
import '../core/auth/secure_store.dart';
import '../core/auth/session.dart';
import '../core/auth/token_source.dart';
import '../core/config/application/config_controller.dart';
import '../core/config/data/config_repository.dart';
import '../core/config/data/key_value_store.dart';
import '../core/env/app_env.dart';
import '../core/env/version.dart';
import '../core/http/api_client.dart';
import '../core/http/app_gate.dart';
import '../core/i18n/locales.dart';
import '../core/realtime/realtime_client.dart';
import '../core/tenant/tenant.generated.dart';
import '../core/tenant/tenant_config.dart';
import '../core/video/providers/fake/fake_video_provider.dart';
import '../core/video/video_provider.dart';
import '../features/entry/application/entry_providers.dart';

final tenantProvider = Provider<TenantConfig>((ref) => generatedTenant);

final envProvider = Provider<AppEnv>(
  (ref) => AppEnv.from(ref.watch(tenantProvider)),
);

/// Idioma do aparelho (testes trocam por um fixo).
final deviceLocaleProvider = Provider<Locale>(
  (ref) => PlatformDispatcher.instance.locale,
);

/// Idioma atual (CFG14): o do aparelho na primeira vez; depois a escolha da
/// pessoa (guardada no aparelho) ou o idioma da conta ao entrar.
final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  /// PreferenciasLocais.idioma (`pt-BR` ou `en`).
  static const prefKey = 'app.language';
  bool _changed = false;

  @override
  Locale build() {
    final tenant = ref.read(tenantProvider);
    unawaited(_loadSaved());
    return initialLocale(
      ref.read(deviceLocaleProvider),
      tenant.supportedLocales,
      tenant.defaultLocale,
    );
  }

  Future<void> _loadSaved() async {
    try {
      final saved = await ref.read(keyValueStoreProvider).read(prefKey);
      if (saved != null && !_changed) state = localeFromTag(saved);
    } on Object catch (e) {
      debugPrint('idioma salvo ilegível: $e');
    }
  }

  /// Troca na hora (sem reiniciar) e guarda no aparelho.
  Future<void> set(Locale locale) async {
    _changed = true;
    if (state == locale) return;
    state = locale;
    try {
      await ref
          .read(keyValueStoreProvider)
          .write(prefKey, acceptLanguageFor(locale));
    } on Object catch (e) {
      debugPrint('não guardou o idioma: $e');
    }
  }
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

/// Portão global (426 → atualizar; 503 manutenção; ENT10 menor bloqueado).
final appGateProvider = NotifierProvider<AppGateController, AppGate>(
  AppGateController.new,
);

class AppGateController extends Notifier<AppGate> {
  /// ENT10: guardado à parte. Quando outro portão (ex.: atualização) sai,
  /// volta o bloqueio de menor, nunca a tela liberada. Só some ao reabrir
  /// o app (o servidor decide de novo).
  GateMinorBlocked? _minor;

  AppGate get _released => _minor ?? const GateOpen();

  @override
  AppGate build() {
    // Config nova sem manutenção (refresh ou config.updated) libera o portão.
    ref.listen(configControllerProvider, (_, next) {
      final c = next.value;
      if (c == null) return;
      // Versão mínima vem na config (GET /config nunca responde 426).
      final appVersion = ref.read(envProvider).appVersion;
      if (compareVersions(appVersion, c.minAppVersion) < 0) {
        state = GateUpdateRequired(c.minAppVersion);
        return;
      }
      if (state is GateUpdateRequired) state = _released;
      if (!c.maintenance.active && state is GateMaintenance) {
        state = _released;
      }
      if (c.regionAllowed && state is GateRegionBlocked) {
        state = _released;
      }
    });
    return const GateOpen();
  }

  void set(AppGate gate) {
    if (gate is GateMinorBlocked) _minor = gate;
    // Atualização obrigatória vence o bloqueio; os demais não o apagam.
    if (_minor != null && gate is! GateUpdateRequired) {
      state = _minor!;
      return;
    }
    state = gate;
  }
}

/// Token de acesso vem da sessão (ADR 0012). Só em debug e só sem sessão,
/// aceita o token de teste do mock (`--dart-define=MOCK_DEV_TOKEN=...`), usado
/// pela vitrine de debug.
final tokenSourceProvider = Provider<TokenSource>(_SessionTokenSource.new);

class _SessionTokenSource implements TokenSource {
  _SessionTokenSource(this._ref);
  final Ref _ref;
  static const _devToken = String.fromEnvironment('MOCK_DEV_TOKEN');

  SessionController get _session => _ref.read(sessionProvider.notifier);

  @override
  Future<String?> accessToken() async =>
      _session.accessToken ??
      (kDebugMode && _devToken.isNotEmpty ? _devToken : null);

  @override
  Future<String?> refreshAccess() => _session.refreshAccess();

  @override
  void sessionEnded(String code, {String? usedToken}) =>
      _session.sessionEnded(code, usedToken: usedToken);
  @override
  void accountOutdated() => _session.accountOutdated();
}

final secureStoreProvider = Provider<SecureStore>(
  (ref) => FlutterSecureStore(),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

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

/// Sobrescreve os providers abstratos do core com as dependências reais.
final appOverrides = [
  sessionDepsProvider.overrideWith(
    (ref) => SessionDeps(
      api: ref.watch(authApiProvider),
      store: ref.watch(secureStoreProvider),
      device: () => ref.read(deviceCredentialsProvider.future),
    ),
  ),
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
  final session = ref.read(sessionProvider.notifier);
  final subs = [
    client.on('config.updated').listen((e) => config.applyRemote(e.data)),
    client.reconnected.listen((_) => config.refresh()),
    // Sessão encerrada pelo servidor no tempo real (ADR 0012).
    client.ended.listen(
      (r) => session.sessionEnded(
        r == RealtimeEnd.replaced ? 'sessao_substituida' : 'sessao_revogada',
      ),
    ),
  ];
  // Entrou: conecta com o token da sessão. Saiu: desconecta.
  ref.listen(sessionProvider, (prev, next) {
    if (prev == null && next != null) {
      unawaited(client.stop().then((_) => client.start()));
    } else if (prev != null && next == null) {
      unawaited(client.stop());
    }
  });
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

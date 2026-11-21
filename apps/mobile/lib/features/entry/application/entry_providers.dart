import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/auth/auth_api.dart';
import '../../../core/auth/session.dart';
import '../../../core/config/application/config_controller.dart';
import '../../../core/device/device_registrar.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/http/app_gate.dart';
import '../../../core/i18n/locales.dart';
import '../../auth/application/auth_flow.dart';
import '../data/entry_prefs.dart';
import '../domain/entry_decision.dart';

final entryPrefsProvider = Provider<EntryPrefs>(
  (ref) => EntryPrefs(ref.watch(keyValueStoreProvider)),
);

/// "Explorar sem conta" (ENT02), guardado no aparelho.
class VisitorModeController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(entryPrefsProvider).visitorMode();

  Future<void> set({required bool on}) async {
    await ref.read(entryPrefsProvider).setVisitorMode(on: on);
    state = AsyncData(on);
  }
}

final visitorModeProvider = AsyncNotifierProvider<VisitorModeController, bool>(
  VisitorModeController.new,
  retry: (retryCount, error) => null,
);

final deviceRegistrarProvider = Provider<DeviceRegistrar>(
  (ref) => DeviceRegistrar(
    ref.watch(apiClientProvider),
    ref.watch(secureStoreProvider),
  ),
);

String _platform() {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}

/// Registro do aparelho em segundo plano (ENT01): não bloqueia a abertura;
/// se falhar, tenta de novo na próxima abertura.
final deviceRegistrationProvider = FutureProvider<DeviceCredentials?>((
  ref,
) async {
  final registrar = ref.read(deviceRegistrarProvider);
  Future<DeviceCredentials> register([Map<String, String>? antibot]) =>
      registrar.register(
        platform: _platform(),
        appVersion: ref.read(envProvider).appVersion,
        locale: acceptLanguageFor(ref.read(localeProvider)),
        antibot: antibot,
        onBlocked: (protocol) =>
            ref.read(appGateProvider.notifier).set(GateMinorBlocked(protocol)),
      );
  try {
    try {
      return await register();
    } on ApiFailure catch (e) {
      // Servidor pediu desafio anti-bot (SEG06): resolve e tenta uma vez mais.
      if (e.code != 'desafio_necessario') rethrow;
      final providers =
          (e.details['providers'] as List?)?.cast<String>() ?? const <String>[];
      final headers = await ref.read(antiBotProvider).solve(providers);
      if (headers == null) rethrow;
      return await register(headers);
    }
  } on Object catch (e) {
    // Não bloqueia a abertura; tenta de novo na próxima (ENT01).
    developer.log('registro do aparelho falhou: $e', name: 'device');
    return null;
  }
}, retry: (retryCount, error) => null);

/// Credenciais do aparelho para login/refresh: as guardadas ou um registro novo.
final deviceCredentialsProvider = FutureProvider<DeviceCredentials?>((
  ref,
) async {
  final stored = await ref.read(deviceRegistrarProvider).stored();
  return stored ?? await ref.read(deviceRegistrationProvider.future);
}, retry: (retryCount, error) => null);

GateKind _gateKind(AppGate g) => switch (g) {
  GateUpdateRequired() => GateKind.updateRequired,
  GateMaintenance() => GateKind.maintenance,
  GateRegionBlocked() => GateKind.regionBlocked,
  GateMinorBlocked() => GateKind.minorBlocked,
  GateOpen() => GateKind.none,
};

/// Para onde o app deve estar agora (ENT01).
final entryDestinationProvider = Provider<EntryDestination>((ref) {
  final config = ref.watch(configControllerProvider);
  final c = config.value;
  final session = ref.watch(sessionProvider);
  return decideEntry(
    config: switch (config) {
      AsyncData() => ConfigStatus.ready,
      AsyncError() => ConfigStatus.error,
      _ => ConfigStatus.loading,
    },
    gate: _gateKind(ref.watch(appGateProvider)),
    regionAllowed: c?.regionAllowed ?? true,
    maintenance: c?.maintenance.active ?? false,
    // Falha ao ler o aparelho conta como "não escolheu" (não prende no splash).
    visitorMode: switch (ref.watch(visitorModeProvider)) {
      AsyncData(:final value) => value,
      AsyncError() => false,
      _ => null,
    },
    hasSession: session != null,
    sessionReady: ref.watch(sessionReadyProvider),
    pendingTerms: session?.pendingTerms.isNotEmpty ?? false,
    pendingSteps: session?.pendingSteps ?? const [],
    sessionEnded: ref.watch(sessionEndNoticeProvider) != null,
  );
});

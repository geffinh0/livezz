import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/app_failure.dart';
import '../data/config_repository.dart';
import '../domain/app_config.dart';

/// Repositório injetado no bootstrap do app.
final configRepositoryProvider = Provider<ConfigRepository>(
  (ref) => throw UnimplementedError('configRepositoryProvider não configurado'),
);

/// Config remota (TRV04): carrega no início, cai no cache sem rede, aplica
/// `config.updated` com versão maior e rebusca ao voltar ao app (ADR 0011)
/// ou ao reconectar o tempo real.
class ConfigController extends AsyncNotifier<AppConfig> {
  ConfigRepository get _repo => ref.read(configRepositoryProvider);

  @override
  Future<AppConfig> build() async {
    try {
      return await _repo.fetch();
    } on AppFailure {
      final cached = await _repo.cached();
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Busca de novo (botão "tentar de novo", app voltou do segundo plano,
  /// tempo real reconectou). Mantém a config atual se falhar.
  Future<void> refresh() async {
    final previous = state.value;
    try {
      final fresh = await _repo.fetch();
      state = AsyncData(fresh);
    } on AppFailure catch (e, st) {
      state = previous != null ? AsyncData(previous) : AsyncError(e, st);
    }
  }

  /// Evento `config.updated` (`data = { configVersion, ...campos }`).
  Future<void> applyRemote(Map<String, dynamic> data) async {
    final current = state.value;
    final version = data['configVersion'];
    if (current == null || version is! int) return;
    if (version <= current.configVersion) return; // velho ou repetido
    final merged = await _repo.applyPartial(data);
    if (merged != null) {
      state = AsyncData(merged);
    } else {
      unawaited(refresh());
    }
  }
}

/// Sem retry automático do Riverpod: a falha vai para a tela, que oferece
/// "tentar de novo" (TRV09). O controller cuida dos novos pedidos.
final configControllerProvider =
    AsyncNotifierProvider<ConfigController, AppConfig>(
      ConfigController.new,
      retry: (retryCount, error) => null,
    );

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_failure.dart';
import 'auth_api.dart';
import 'secure_store.dart';

/// Sessão autenticada (ADR 0012). `needsProfile` → cadastro (1c);
/// `pendingTerms` → aceite de termos (ENT16).
class Session {
  const Session({
    required this.userId,
    this.needsProfile = false,
    this.pendingTerms = const [],
  });
  final String userId;
  final bool needsProfile;
  final List<PendingTerm> pendingTerms;

  Session copyWith({bool? needsProfile, List<PendingTerm>? pendingTerms}) =>
      Session(
        userId: userId,
        needsProfile: needsProfile ?? this.needsProfile,
        pendingTerms: pendingTerms ?? this.pendingTerms,
      );
}

/// Dependências da sessão, injetadas no bootstrap (testes trocam por falsos).
class SessionDeps {
  const SessionDeps({
    required this.api,
    required this.store,
    required this.device,
  });
  final AuthApi api;
  final SecureStore store;
  final Future<DeviceCredentials?> Function() device;
}

final sessionDepsProvider = Provider<SessionDeps?>((ref) => null);

/// A tentativa de restaurar a sessão guardada terminou (ENT01 espera por ela).
final sessionReadyProvider = NotifierProvider<SessionReady, bool>(
  SessionReady.new,
);

class SessionReady extends Notifier<bool> {
  @override
  bool build() => false;
  void set() => state = true;
}

/// Por que a sessão acabou (para o aviso na tela de entrada).
final sessionEndNoticeProvider = NotifierProvider<SessionEndNotice, String?>(
  SessionEndNotice.new,
);

class SessionEndNotice extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? code) => state = code;
}

class SessionController extends Notifier<Session?> {
  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';
  static const _kUser = 'auth.user';

  /// Códigos que significam "a sessão acabou" no servidor (ADR 0012).
  static const endedCodes = {
    'sessao_substituida',
    'sessao_revogada',
    'sessao_expirada',
    'dispositivo_invalido',
    'conta_banida',
    'conta_suspensa',
  };

  String? _access;
  String? _refresh;
  Future<String?>? _refreshing;

  /// Geração da sessão: muda a cada login e a cada limpeza. Resultados de
  /// operações iniciadas numa geração antiga são descartados (sem corrida).
  int _gen = 0;

  SessionDeps? get _deps => ref.read(sessionDepsProvider);

  @override
  Session? build() => null;

  /// Só para testes de tela.
  void set(Session? session) => state = session;

  String? get accessToken => _access;

  /// ENT01: restaura a sessão guardada e valida no servidor.
  Future<void> restore() async {
    try {
      await _restore();
    } on Object catch (e) {
      // Armazenamento ilegível: segue sem sessão (visitante).
      developer.log('restaurar sessão falhou: $e', name: 'auth');
      await _clear().catchError((Object _) {});
    } finally {
      ref.read(sessionReadyProvider.notifier).set();
    }
  }

  Future<void> _restore() async {
    final deps = _deps;
    if (deps == null) return;
    final access = await deps.store.read(_kAccess);
    final refresh = await deps.store.read(_kRefresh);
    final userId = await deps.store.read(_kUser);
    if (access == null || refresh == null || userId == null) return;
    _access = access;
    _refresh = refresh;
    final gen = ++_gen;
    try {
      final me = await deps.api.me();
      if (gen == _gen) state = _fromMe(me);
    } on ApiFailure catch (e) {
      if (gen != _gen) return;
      if (endedCodes.contains(e.code) || e.code == 'nao_autenticado') {
        if (endedCodes.contains(e.code)) {
          ref.read(sessionEndNoticeProvider.notifier).set(e.code);
        }
        await _clear();
        return;
      }
      // Erro passageiro (500, 503, 429…): mantém a sessão; o servidor
      // continua barrando o que for preciso (ex.: termos pendentes).
      state = Session(userId: userId);
    } on AppFailure {
      // Sem rede: entra com o que estava guardado; o servidor revalida depois.
      if (gen == _gen) state = Session(userId: userId);
    }
  }

  Session _fromMe(Me me) => Session(
    userId: me.id,
    needsProfile: me.needsProfile,
    pendingTerms: me.pendingTerms,
  );

  /// O servidor respondeu `403 termos_pendentes` com o app aberto (ENT16):
  /// recarrega o `/me` para o roteador levar à tela de termos.
  void termsPending() {
    unawaited(
      reloadMe().catchError((Object e) {
        developer.log('reloadMe falhou: $e', name: 'auth');
      }),
    );
  }

  Future<void> reloadMe() async {
    final deps = _deps;
    if (deps == null || _access == null) return;
    final gen = _gen;
    final me = await deps.api.me();
    if (gen == _gen) state = _fromMe(me);
  }

  /// Depois de qualquer login (telefone, e-mail, Google). A sessão só é
  /// publicada depois do `/me`, para o roteador já saber dos termos pendentes.
  Future<void> signedIn(TokenResponse t) async {
    final deps = _deps;
    final gen = ++_gen;
    _access = t.accessToken;
    _refresh = t.refreshToken;
    if (deps != null) {
      await deps.store.write(_kAccess, t.accessToken);
      await deps.store.write(_kRefresh, t.refreshToken);
      await deps.store.write(_kUser, t.userId);
    }
    ref.read(sessionEndNoticeProvider.notifier).set(null);
    var session = Session(userId: t.userId, needsProfile: t.needsProfile);
    try {
      if (deps != null) session = _fromMe(await deps.api.me());
    } on AppFailure catch (e) {
      developer.log('me após login falhou: $e', name: 'auth');
    }
    if (gen == _gen) state = session;
  }

  /// Renova o access (fila única: chamadas simultâneas esperam a mesma
  /// renovação). Null = a sessão acabou. Lança [NetworkFailure] sem rede.
  Future<String?> refreshAccess() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<String?> _doRefresh() async {
    final deps = _deps;
    final refresh = _refresh;
    if (deps == null || refresh == null) return null;
    final gen = _gen;
    final device = await deps.device();
    if (device == null) throw const NetworkFailure();
    try {
      final t = await deps.api.refresh(refresh, device);
      if (gen != _gen) return null; // saiu ou entrou de novo no meio
      _access = t.accessToken;
      _refresh = t.refreshToken;
      await deps.store.write(_kAccess, t.accessToken);
      await deps.store.write(_kRefresh, t.refreshToken);
      return t.accessToken;
    } on ApiFailure catch (e) {
      if (gen == _gen) sessionEnded(e.code);
      return null;
    }
  }

  /// O servidor encerrou a sessão: limpa e guarda o motivo para o aviso.
  /// [usedToken] é o access usado na requisição que falhou: se não for o
  /// atual (resposta atrasada de uma sessão anterior), ignora.
  void sessionEnded(String code, {String? usedToken}) {
    if (state == null && _access == null) return;
    if (usedToken != null && usedToken != _access) return;
    ref.read(sessionEndNoticeProvider.notifier).set(code);
    unawaited(_clear());
  }

  /// Sair: avisa o servidor (sem bloquear) e limpa tudo, mesmo sem rede.
  Future<void> signOut() async {
    final deps = _deps;
    final access = _access;
    final refresh = _refresh;
    await _clear();
    if (deps != null) {
      unawaited(
        deps.api
            .logout(accessToken: access, refreshToken: refresh)
            .catchError((Object _) {}),
      );
    }
  }

  Future<void> _clear() async {
    _gen++;
    _access = null;
    _refresh = null;
    state = null;
    final deps = _deps;
    if (deps != null) {
      for (final k in [_kAccess, _kRefresh, _kUser]) {
        await deps.store.delete(k);
      }
    }
  }
}

final sessionProvider = NotifierProvider<SessionController, Session?>(
  SessionController.new,
);

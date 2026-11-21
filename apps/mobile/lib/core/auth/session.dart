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

  String? _access;
  String? _refresh;
  Future<String?>? _refreshing;

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
    } finally {
      ref.read(sessionReadyProvider.notifier).set();
    }
  }

  Future<void> _restore() async {
    final deps = _deps;
    if (deps == null) return;
    _access = await deps.store.read(_kAccess);
    _refresh = await deps.store.read(_kRefresh);
    final userId = await deps.store.read(_kUser);
    if (_access == null || _refresh == null || userId == null) return;
    state = Session(userId: userId);
    try {
      await reloadMe();
    } on ApiFailure catch (e) {
      if (e.status == 401 || e.status == 403) await _clear();
    } on AppFailure {
      // sem rede: mantém a sessão guardada; o servidor revalida na próxima chamada
    }
  }

  Future<void> reloadMe() async {
    final deps = _deps;
    if (deps == null || state == null) return;
    final me = await deps.api.me();
    state = Session(
      userId: me.id,
      needsProfile: me.needsProfile,
      pendingTerms: me.pendingTerms,
    );
  }

  /// Depois de qualquer login (telefone, e-mail, Google).
  Future<void> signedIn(TokenResponse t) async {
    final deps = _deps;
    _access = t.accessToken;
    _refresh = t.refreshToken;
    if (deps != null) {
      await deps.store.write(_kAccess, t.accessToken);
      await deps.store.write(_kRefresh, t.refreshToken);
      await deps.store.write(_kUser, t.userId);
    }
    ref.read(sessionEndNoticeProvider.notifier).set(null);
    state = Session(userId: t.userId, needsProfile: t.needsProfile);
    try {
      await reloadMe();
    } on AppFailure catch (e) {
      developer.log('me após login falhou: $e', name: 'auth');
    }
  }

  /// Renova o access (fila única: chamadas simultâneas esperam a mesma renovação).
  Future<String?> refreshAccess() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<String?> _doRefresh() async {
    final deps = _deps;
    final refresh = _refresh;
    if (deps == null || refresh == null) return null;
    final device = await deps.device();
    if (device == null) return null;
    try {
      final t = await deps.api.refresh(refresh, device);
      _access = t.accessToken;
      _refresh = t.refreshToken;
      await deps.store.write(_kAccess, t.accessToken);
      await deps.store.write(_kRefresh, t.refreshToken);
      return t.accessToken;
    } on ApiFailure catch (e) {
      sessionEnded(e.code);
      return null;
    } on AppFailure {
      return null; // sem rede: tenta de novo depois
    }
  }

  /// O servidor encerrou a sessão: limpa e guarda o motivo para o aviso.
  void sessionEnded(String code) {
    if (state == null && _access == null) return;
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
    _access = null;
    _refresh = null;
    final deps = _deps;
    if (deps != null) {
      for (final k in [_kAccess, _kRefresh, _kUser]) {
        await deps.store.delete(k);
      }
    }
    state = null;
  }
}

final sessionProvider = NotifierProvider<SessionController, Session?>(
  SessionController.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ação que o visitante tentou fazer antes de entrar (ENT17), ou a tela onde
/// a sessão expirou (ENT19). Só em memória e expira; quem executa é o
/// roteador, quando o destino passa a ser a Home (depois de termos/cadastro).
/// A ação é revalidada no servidor quando roda (ela mesma chama a API).
class PendingAction {
  PendingAction(this.run, {DateTime? at}) : createdAt = at ?? DateTime.now();
  final Future<void> Function() run;
  final DateTime createdAt;
  static const ttl = Duration(minutes: 5);
  bool isExpired(DateTime now) => now.difference(createdAt) > ttl;
}

class PendingActionController extends Notifier<PendingAction?> {
  @override
  PendingAction? build() => null;

  DateTime Function() _now = DateTime.now;

  // Só para testes.
  // ignore: use_setters_to_change_properties
  void setClock(DateTime Function() now) => _now = now;

  /// Guarda a ação. Uma ação do visitante (ENT17) não é trocada pela volta
  /// automática de sessão expirada ([keepExisting]).
  void hold(PendingAction action, {bool keepExisting = false}) {
    if (keepExisting && state != null && !state!.isExpired(_now())) return;
    state = action;
  }

  void clear() => state = null;

  /// Entrega a ação (uma vez) se ainda não expirou.
  PendingAction? take() {
    final action = state;
    state = null;
    if (action == null || action.isExpired(_now())) return null;
    return action;
  }
}

final pendingActionProvider =
    NotifierProvider<PendingActionController, PendingAction?>(
      PendingActionController.new,
    );

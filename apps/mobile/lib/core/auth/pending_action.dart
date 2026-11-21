import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';

/// Ação que o visitante tentou fazer antes de entrar (ENT17). Só em memória,
/// expira, e a ação é revalidada no servidor quando roda (ela mesma chama a API).
class PendingAction {
  PendingAction(this.run, {DateTime? at}) : createdAt = at ?? DateTime.now();
  final Future<void> Function() run;
  final DateTime createdAt;
  static const ttl = Duration(minutes: 5);
  bool isExpired(DateTime now) => now.difference(createdAt) > ttl;
}

class PendingActionController extends Notifier<PendingAction?> {
  @override
  PendingAction? build() {
    // Quando a sessão aparece, executa a ação guardada (se não expirou).
    ref.listen(sessionProvider, (previous, next) {
      if (previous == null && next != null) {
        final action = state;
        state = null;
        if (action != null && !action.isExpired(_now())) {
          // Espera o roteador assentar (ele também reage à sessão nova).
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 150))
                .then((_) => action.run())
                .catchError((Object e) {
                  developer.log('ação pendente falhou: $e', name: 'auth');
                }),
          );
        }
      }
    });
    return null;
  }

  DateTime Function() _now = DateTime.now;

  // Só para testes.
  // ignore: use_setters_to_change_properties
  void setClock(DateTime Function() now) => _now = now;

  void hold(PendingAction action) => state = action;
  void clear() => state = null;
}

final pendingActionProvider =
    NotifierProvider<PendingActionController, PendingAction?>(
      PendingActionController.new,
    );

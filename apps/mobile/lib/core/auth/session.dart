import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sessão autenticada. Na Fase 1a nunca há sessão (o login chega no plano 1b,
/// ENT04–ENT07 e ENT19); os testes usam sessão falsa.
class Session {
  const Session({required this.userId});
  final String userId;
}

class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;
  void set(Session? session) => state = session;
}

final sessionProvider = NotifierProvider<SessionController, Session?>(
  SessionController.new,
);

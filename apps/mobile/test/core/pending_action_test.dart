import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/auth/pending_action.dart';

void main() {
  test('take entrega a ação uma vez', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(pendingActionProvider.notifier)
      ..hold(PendingAction(() async {}));
    expect(n.take(), isNotNull);
    expect(n.take(), isNull);
  });

  test('ação expirada (5 min) não é entregue', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final t0 = DateTime(2026);
    final n = c.read(pendingActionProvider.notifier)
      ..setClock(() => t0.add(const Duration(minutes: 6)))
      ..hold(PendingAction(() async {}, at: t0));
    expect(n.take(), isNull);
  });

  test('volta automática não troca a ação do visitante (keepExisting)', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    var which = '';
    final n = c.read(pendingActionProvider.notifier)
      ..hold(PendingAction(() async => which = 'visitante'))
      ..hold(PendingAction(() async => which = 'rota'), keepExisting: true);
    n.take()!.run();
    expect(which, 'visitante');
  });
}

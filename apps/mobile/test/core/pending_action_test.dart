import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/auth/pending_action.dart';
import 'package:livezz_mobile/core/auth/session.dart';

void main() {
  test('ação guardada roda quando a sessão aparece', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    var ran = 0;
    c
        .read(pendingActionProvider.notifier)
        .hold(PendingAction(() async => ran++));
    c.read(sessionProvider.notifier).set(const Session(userId: 'u-ana'));
    await Future<void>.delayed(Duration.zero);
    expect(ran, 1);
    expect(c.read(pendingActionProvider), isNull);
  });

  test('ação expirada (5 min) não roda', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    var ran = 0;
    final t0 = DateTime(2026);
    c.read(pendingActionProvider.notifier)
      ..setClock(() => t0.add(const Duration(minutes: 6)))
      ..hold(PendingAction(() async => ran++, at: t0));
    c.read(sessionProvider.notifier).set(const Session(userId: 'u-ana'));
    await Future<void>.delayed(Duration.zero);
    expect(ran, 0);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/errors/app_failure.dart';
import 'package:livezz_mobile/core/ui/state_views.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/harness.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget w) =>
      t.pumpWidget(harness(Scaffold(body: w)));

  testWidgets('carregando', (t) async {
    await pump(t, const StateView.loading());
    expect(find.byKey(const ValueKey('state.loading')), findsOneWidget);
    expect(find.bySemanticsLabel('Carregando…'), findsOneWidget);
  });

  testWidgets('vazio com ação', (t) async {
    var tapped = false;
    await pump(
      t,
      StateView.empty(actionLabel: 'Criar', onAction: () => tapped = true),
    );
    expect(find.text('Nada por aqui ainda'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('state.empty.action')));
    expect(tapped, isTrue);
  });

  testWidgets('erro com tentar de novo', (t) async {
    var retries = 0;
    await pump(t, StateView.error(onRetry: () => retries++));
    expect(find.text('Não deu certo'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('state.error.action')));
    expect(retries, 1);
  });

  testWidgets('sem conexão', (t) async {
    await pump(t, StateView.offline(onRetry: () {}));
    expect(find.text('Sem conexão'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('sem permissão', (t) async {
    await pump(t, StateView.noPermission(onOpenSettings: () {}));
    expect(find.text('Permissão necessária'), findsOneWidget);
    expect(find.text('Abrir configurações'), findsOneWidget);
  });

  testWidgets('forFailure traduz pelo error.code', (t) async {
    await t.pumpWidget(
      harness(
        Scaffold(
          body: Builder(
            builder: (c) => StateView.forFailure(
              c,
              const ApiFailure(status: 402, code: 'saldo_insuficiente'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Saldo insuficiente.'), findsOneWidget);
  });

  testWidgets('forFailure: rede → sem conexão', (t) async {
    await t.pumpWidget(
      harness(
        Scaffold(
          body: Builder(
            builder: (c) => StateView.forFailure(c, const NetworkFailure()),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('state.offline')), findsOneWidget);
  });

  testWidgets('botão de ação tem alvo de toque >= 48dp', (t) async {
    await pump(t, StateView.error(onRetry: () {}));
    final size = t.getSize(find.byKey(const ValueKey('state.error.action')));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}

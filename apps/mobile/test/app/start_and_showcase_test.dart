import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/app/start_screen.dart';
import 'package:livezz_mobile/features/dev_showcase/presentation/showcase_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('início: erro 500 mostra erro e "tentar de novo" recupera', (
    t,
  ) async {
    var fail = true;
    final adapter = StubAdapter(
      (_) => fail
          ? jsonBody(500, {
              'error': {'code': 'erro_interno', 'requestId': 'r'},
            })
          : jsonBody(200, sampleConfig()),
    );
    await t.pumpWidget(
      harness(const StartScreen(), overrides: testOverrides(adapter)),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('state.error')), findsOneWidget);
    expect(
      find.text('Tivemos um problema no servidor. Tente de novo em instantes.'),
      findsOneWidget,
    );
    fail = false;
    await t.tap(find.byKey(const ValueKey('state.error.action')));
    await t.pump();
    expect(find.byKey(const ValueKey('state.loading')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('state.error')), findsNothing);
  });

  group('vitrine', () {
    final adapter = StubAdapter((_) => jsonBody(200, sampleConfig(version: 7)));

    Future<void> pumpShowcase(
      WidgetTester t, {
      Locale locale = const Locale('pt'),
      ThemeMode mode = ThemeMode.light,
      TextDirection? direction,
      double textScale = 1,
    }) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        harness(
          const ShowcaseScreen(),
          overrides: testOverrides(adapter),
          locale: locale,
          mode: mode,
          direction: direction,
          textScale: textScale,
        ),
      );
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('mostra marca do tenant, versão da config e tempo real', (
      t,
    ) async {
      await pumpShowcase(t);
      expect(find.text('liveapp'), findsOneWidget);
      expect(find.text('Versão da config: 7'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('showcase.realtime.disconnected')),
        findsOneWidget,
      );
    });

    testWidgets('em inglês', (t) async {
      await pumpShowcase(t, locale: const Locale('en'));
      expect(find.text('Foundation showcase'), findsOneWidget);
      expect(find.text('Config version: 7'), findsOneWidget);
    });

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('renderiza no tema ${mode.name} sem erros', (t) async {
        await pumpShowcase(t, mode: mode);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('RTL e fonte 2x sem overflow', (t) async {
      await pumpShowcase(t, direction: TextDirection.rtl, textScale: 2);
      expect(t.takeException(), isNull);
      // rola até o fim para construir todos os itens
      await t.drag(find.byType(ListView), const Offset(0, -3000));
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('abre bottom sheet e diálogo', (t) async {
      await pumpShowcase(t);
      await t.ensureVisible(find.byKey(const ValueKey('showcase.openSheet')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('showcase.openSheet')));
      await t.pump(const Duration(seconds: 1));
      expect(
        find.text('Fluxos da live abrem aqui, sem sair do vídeo.'),
        findsOneWidget,
      );
      await t.tapAt(const Offset(10, 10));
      await t.pump(const Duration(seconds: 1));
      await t.ensureVisible(find.byKey(const ValueKey('showcase.openDialog')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('showcase.openDialog')));
      await t.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('dialog.confirm')), findsOneWidget);
    });
  });
}

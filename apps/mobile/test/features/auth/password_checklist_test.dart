import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/ui/app_text_field.dart';
import 'package:livezz_mobile/features/auth/presentation/password_checklist.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/harness.dart';

Widget _wrap(Widget child) => harness(Scaffold(body: child));

void main() {
  testWidgets('checklist marca regra atendida com ícone e rótulo, não só cor', (
    t,
  ) async {
    await t.pumpWidget(_wrap(const PasswordChecklist(password: 'abc')));
    expect(find.byIcon(Symbols.cancel), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Regra não atendida')), findsWidgets);

    await t.pumpWidget(
      _wrap(const PasswordChecklist(password: 'senhaforte123')),
    );
    expect(find.byIcon(Symbols.cancel), findsNothing);
    expect(find.byIcon(Symbols.check_circle), findsNWidgets(3));
  });

  testWidgets('campo de senha alterna mostrar/esconder', (t) async {
    final ctrl = TextEditingController(text: 'segredo1');
    await t.pumpWidget(
      _wrap(AppTextField(label: 'Senha', controller: ctrl, password: true)),
    );
    expect(t.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await t.tap(find.byTooltip('Mostrar senha'));
    await t.pump();
    expect(t.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
  });

  testWidgets('erro de validação aparece ao sair do campo', (t) async {
    final ctrl = TextEditingController();
    await t.pumpWidget(
      _wrap(
        Column(
          children: [
            AppTextField(
              label: 'E-mail',
              controller: ctrl,
              validator: (v) => v.contains('@') ? null : 'inválido',
            ),
            const TextField(),
          ],
        ),
      ),
    );
    await t.enterText(find.byType(TextField).first, 'sem-arroba');
    await t.tap(find.byType(TextField).last);
    await t.pump();
    expect(find.text('inválido'), findsOneWidget);
  });
}

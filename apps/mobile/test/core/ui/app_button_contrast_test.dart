import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/theme/contrast.dart';
import 'package:livezz_mobile/core/ui/app_button.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/harness.dart';

/// Mede o contraste do texto REALMENTE desenhado em cada variante de botão,
/// contra o fundo do botão (ou da tela, nos botões sem fundo).
void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final variant in AppButtonVariant.values) {
      testWidgets('${variant.name} no tema ${mode.name} passa AA', (t) async {
        await t.pumpWidget(
          harness(
            Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Rótulo',
                  variant: variant,
                  onPressed: () {},
                ),
              ),
            ),
            mode: mode,
          ),
        );
        final ctx = t.element(find.byType(AppButton));
        final scheme = Theme.of(ctx).colorScheme;
        final text = t.renderObject<RenderParagraph>(find.text('Rótulo'));
        final fg = text.text.style?.color;
        final hasFill =
            variant == AppButtonVariant.primary ||
            variant == AppButtonVariant.danger;
        final bg = switch (variant) {
          AppButtonVariant.primary => scheme.primary,
          AppButtonVariant.danger => scheme.error,
          _ => scheme.surface,
        };
        expect(fg, isNotNull);
        expect(
          contrastRatio(fg!, bg),
          greaterThanOrEqualTo(4.5),
          reason: 'texto $fg sobre $bg (fundo próprio: $hasFill)',
        );
      });
    }
  }
}

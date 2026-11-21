import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/tenant/tenant.generated.dart';
import 'package:livezz_mobile/core/theme/app_theme.dart';
import 'package:livezz_mobile/core/theme/contrast.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final theme = AppTheme(generatedTenant);

  test('calculadora de contraste confere com valores conhecidos', () {
    expect(contrastRatio(Colors.white, Colors.black), closeTo(21, 0.01));
    expect(
      contrastRatio(const Color(0xFFE91E8C), Colors.white),
      closeTo(4.18, 0.02),
    );
  });

  for (final entry in {'claro': theme.light, 'escuro': theme.dark}.entries) {
    group('tema ${entry.key}', () {
      final s = entry.value.colorScheme;

      test('pares de texto passam AA (>= 4,5:1)', () {
        final pairs = {
          'onPrimary/primary': (s.onPrimary, s.primary),
          'onSecondary/secondary': (s.onSecondary, s.secondary),
          'onSurface/surface': (s.onSurface, s.surface),
          'onSurface/surfaceContainer': (s.onSurface, s.surfaceContainer),
          'onError/error': (s.onError, s.error),
        };
        for (final p in pairs.entries) {
          expect(
            contrastRatio(p.value.$1, p.value.$2),
            greaterThanOrEqualTo(4.5),
            reason: p.key,
          );
        }
      });

      test('usa a fonte do tenant', () {
        expect(
          entry.value.textTheme.bodyMedium?.fontFamily,
          generatedTenant.fontFamily,
        );
      });

      test('botões têm alvo de toque >= 48dp', () {
        final size = entry.value.filledButtonTheme.style?.minimumSize?.resolve(
          <WidgetState>{},
        );
        expect(size?.height, greaterThanOrEqualTo(48));
      });
    });
  }

  test('marca do tenant liveapp (Q-42)', () {
    expect(generatedTenant.colors.primary, const Color(0xFFE91E8C));
    expect(theme.dark.colorScheme.primary, const Color(0xFFD6157E));
  });
}

import 'package:material_ui/material_ui.dart';

import '../tenant/tenant_config.dart';
import 'tokens.dart';

/// Tema claro e escuro a partir das cores e fonte do tenant (CFG08, Q-42).
/// Regra: texto branco nunca sobre `primary` em texto pequeno — botões usam
/// `primaryAction` / `onPrimaryAction` (contraste AA).
class AppTheme {
  const AppTheme(this.tenant);

  final TenantConfig tenant;

  ThemeData get light => _build(Brightness.light);
  ThemeData get dark => _build(Brightness.dark);

  ThemeData _build(Brightness brightness) {
    final c = tenant.colors;
    final isDark = brightness == Brightness.dark;
    final background = isDark ? c.darkBackground : c.lightBackground;
    final onBackground = isDark ? Colors.white : const Color(0xFF14141A);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primaryAction,
      onPrimary: c.onPrimaryAction,
      secondary: c.secondary,
      onSecondary: c.onSecondary,
      tertiary: c.primary,
      onTertiary: c.onPrimaryAction,
      error: isDark ? AppStatusColors.dangerDark : AppStatusColors.dangerLight,
      onError: isDark ? const Color(0xFF14141A) : Colors.white,
      surface: background,
      onSurface: onBackground,
      surfaceContainer: isDark ? kDarkSurface : kLightSurface,
      onSurfaceVariant: onBackground.withValues(alpha: 0.6),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: tenant.fontFamily,
      scaffoldBackgroundColor: background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, onBackground),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(kMinTouchTarget * 2, kMinTouchTarget),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(kMinTouchTarget * 2, kMinTouchTarget),
          shape: const StadiumBorder(),
          // No escuro, primaryAction sobre o fundo fica abaixo de AA: usa a marca.
          foregroundColor: isDark ? c.primary : c.primaryAction,
          side: BorderSide(color: isDark ? c.primary : c.primaryAction),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
          foregroundColor: isDark ? c.primary : c.primaryAction,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  TextTheme _textTheme(TextTheme base, Color color) {
    // Escala do DESIGN-SYSTEM: 12 / 14 / 16 / 20 / 24 / 32.
    TextStyle s(TextStyle? b, double size, FontWeight w) =>
        (b ?? const TextStyle()).copyWith(
          fontFamily: tenant.fontFamily,
          fontSize: size,
          fontWeight: w,
        );
    return base.copyWith(
      displaySmall: s(base.displaySmall, 32, FontWeight.w700),
      headlineSmall: s(base.headlineSmall, 24, FontWeight.w700),
      titleLarge: s(base.titleLarge, 20, FontWeight.w600),
      titleMedium: s(base.titleMedium, 16, FontWeight.w600),
      bodyLarge: s(base.bodyLarge, 16, FontWeight.w400),
      bodyMedium: s(base.bodyMedium, 14, FontWeight.w400),
      labelLarge: s(base.labelLarge, 14, FontWeight.w600),
      bodySmall: s(base.bodySmall, 12, FontWeight.w400),
      labelSmall: s(base.labelSmall, 12, FontWeight.w500),
    );
  }
}

import 'package:material_ui/material_ui.dart';

/// Tokens do design system (docs/DESIGN-SYSTEM.md §2). Cores vêm do tenant;
/// o resto é fixo do produto.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const field = 8.0;
  static const card = 16.0;
  static const sheet = 24.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
}

/// Alvo mínimo de toque (acessibilidade): 48dp.
const double kMinTouchTarget = 48;

/// Cores de estado e economia (sempre com ícone, nunca só cor).
abstract final class AppStatusColors {
  static const successDark = Color(0xFF4ADE80);
  static const successLight = Color(0xFF15803D);
  static const warningDark = Color(0xFFFBBF24);
  static const warningLight = Color(0xFFB45309);
  static const dangerDark = Color(0xFFF87171);
  static const dangerLight = Color(0xFFB91C1C);
  static const coin = Color(0xFFF5B301);
  static const diamond = Color(0xFF38BDF8);
}

/// Superfície escura padrão (cards, sheets) — DESIGN-SYSTEM.
const Color kDarkSurface = Color(0xFF1A1A22);
const Color kLightSurface = Color(0xFFF4F4F6);

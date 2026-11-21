import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Razão de contraste WCAG 2.x entre duas cores opacas.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

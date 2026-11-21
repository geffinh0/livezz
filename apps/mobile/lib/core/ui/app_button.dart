import 'package:material_ui/material_ui.dart';

import 'app_spinner.dart';

enum AppButtonVariant { primary, secondary, text, danger }

/// Botão único do app (DESIGN-SYSTEM §3): primário, secundário, texto e
/// perigo; estados carregando e desabilitado.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    // Carregando: o botão fica desabilitado (anunciado assim) e o leitor de
    // tela continua ouvindo o rótulo.
    final child = loading
        ? Semantics(
            label: label,
            liveRegion: true,
            child: SizedBox.square(
              dimension: 20,
              child: AppSpinner(
                color: variant == AppButtonVariant.primary
                    ? scheme.onPrimary
                    : scheme.primary,
              ),
            ),
          )
        : Text(label);
    final action = enabled ? onPressed : null;
    final iconWidget = icon == null || loading ? null : Icon(icon);
    final button = switch (variant) {
      AppButtonVariant.primary =>
        iconWidget == null
            ? FilledButton(onPressed: action, child: child)
            : FilledButton.icon(
                onPressed: action,
                icon: iconWidget,
                label: child,
              ),
      AppButtonVariant.secondary =>
        iconWidget == null
            ? OutlinedButton(onPressed: action, child: child)
            : OutlinedButton.icon(
                onPressed: action,
                icon: iconWidget,
                label: child,
              ),
      AppButtonVariant.text => TextButton(onPressed: action, child: child),
      AppButtonVariant.danger => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
        ),
        onPressed: action,
        child: child,
      ),
    };
    return button;
  }
}

import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Indicador de carregamento que respeita "reduzir animações"
/// (DESIGN-SYSTEM §1.6): com animações desligadas, mostra um ícone parado.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.color, this.size});

  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Icon(Symbols.hourglass_empty, color: color, size: size);
    }
    return CircularProgressIndicator(strokeWidth: 2, color: color);
  }
}

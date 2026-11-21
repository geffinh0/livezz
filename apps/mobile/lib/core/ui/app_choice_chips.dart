import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';
import 'test_id.dart';

/// Escolha múltipla em chips (DESIGN-SYSTEM §3), ex.: interesses (ENT12).
/// Selecionado tem ícone de check além da cor (nunca só cor). Alvo ≥ 48dp.
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
    super.key,
    this.idOf,
    this.max,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onToggle;

  /// Id estável para E2E (`TestId`).
  final String Function(T)? idOf;

  /// Limite de escolhas: além dele, os não escolhidos ficam desligados.
  final int? max;

  @override
  Widget build(BuildContext context) {
    final full = max != null && selected.length >= max!;
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final o in options)
          _wrapId(
            o,
            FilterChip(
              label: Text(labelOf(o)),
              selected: selected.contains(o),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: full && !selected.contains(o)
                  ? null
                  : (_) => onToggle(o),
            ),
          ),
      ],
    );
  }

  Widget _wrapId(T o, Widget child) =>
      idOf == null ? child : TestId(idOf!(o), child: child);
}

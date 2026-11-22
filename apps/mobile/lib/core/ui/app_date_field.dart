import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';

/// Campo de data (DESIGN-SYSTEM §3): mostra a data no idioma do app e abre o
/// seletor do sistema (acessível, com digitação). Erro e ajuda no próprio campo.
class AppDateField extends StatelessWidget {
  const AppDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    super.key,
    this.initialDate,
    this.helper,
    this.error,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  /// Onde o seletor abre quando ainda não há valor.
  final DateTime? initialDate;
  final String? helper;
  final String? error;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? initialDate ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.year,
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = value == null
        ? ''
        : MaterialLocalizations.of(context).formatMediumDate(value!);
    // Sem esconder a semântica de dentro: o leitor de tela lê rótulo, valor,
    // ajuda e o erro do próprio campo.
    return Semantics(
      button: true,
      hint: text.isEmpty ? l.birthDateChoose : l.birthDateChange,
      child: InkWell(
        onTap: enabled ? () => _pick(context) : null,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            helperMaxLines: 2,
            errorText: error,
            enabled: enabled,
            suffixIcon: const Icon(Symbols.calendar_month),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

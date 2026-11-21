import 'package:material_ui/material_ui.dart';

/// Campo de texto padrão: rótulo, ajuda, erro e contador.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.helper,
    this.error,
    this.maxLength,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final String? helper;
  final String? error;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLength: maxLength,
    onChanged: onChanged,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      errorText: error,
    ),
  );
}

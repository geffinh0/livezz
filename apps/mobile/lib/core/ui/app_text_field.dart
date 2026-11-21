import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';

/// Campo de texto padrão (DESIGN-SYSTEM §3): rótulo, ajuda, erro no próprio
/// campo, contador, senha com mostrar/esconder e validação ao sair do campo.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.helper,
    this.error,
    this.maxLength,
    this.showCounter = true,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.hint,
    this.password = false,
    this.enabled = true,
    this.validator,
    this.style,
    this.semanticsHint,
  });

  final String label;
  final TextEditingController? controller;
  final String? helper;

  /// Erro vindo de fora (ex.: servidor). Tem prioridade sobre o [validator].
  final String? error;
  final int? maxLength;
  final bool showCounter;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final String? hint;
  final bool password;
  final bool enabled;

  /// Validação local, mostrada quando o campo perde o foco.
  final String? Function(String value)? validator;
  final TextStyle? style;

  /// Dica extra para o leitor de tela (ex.: "6 dígitos").
  final String? semanticsHint;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();
  bool _obscure = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && widget.validator != null) {
        setState(
          () => _localError = widget.validator!(widget.controller?.text ?? ''),
        );
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      onChanged: (v) {
        if (_localError != null) setState(() => _localError = null);
        widget.onChanged?.call(v);
      },
      onSubmitted: widget.onSubmitted,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      obscureText: widget.password && _obscure,
      style: widget.style,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        errorText: widget.error ?? _localError,
        counterText: widget.showCounter ? null : '',
        suffixIcon: widget.password
            ? IconButton(
                tooltip: _obscure ? l.passwordShow : l.passwordHide,
                icon: Icon(
                  _obscure ? Symbols.visibility : Symbols.visibility_off,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
    return widget.semanticsHint == null
        ? field
        : Semantics(hint: widget.semanticsHint, child: field);
  }
}

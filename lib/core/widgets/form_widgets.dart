import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renti/core/theme/app_theme.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 0, 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.ink,
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const SectionTitle(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(0, 22, 0, 12),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: context.ink,
          ),
        ),
      );
}

InputDecoration _decoration(BuildContext context, String hint) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: 1.5),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.muted, fontSize: 16),
    filled: true,
    fillColor: context.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    enabledBorder: border(context.line),
    focusedBorder: border(RentiColors.blue),
    border: border(context.line),
  );
}

/// Campo de texto con etiqueta (opcional) encima.
///
/// Es un `TextFormField`: dentro de un `Form` participa en `validate()` y
/// muestra el mensaje de error del [validator] debajo del campo.
class RentiTextField extends StatefulWidget {
  final String? label;
  final String hint;
  final TextEditingController? controller;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  const RentiTextField({
    super.key,
    this.label,
    required this.hint,
    this.controller,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  @override
  State<RentiTextField> createState() => _RentiTextFieldState();
}

class _RentiTextFieldState extends State<RentiTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final deco = _decoration(context, widget.hint).copyWith(
      counterText: '',
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
      suffixIcon: widget.obscure
          ? IconButton(
              tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
              icon: Icon(
                _hidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: context.muted,
              ),
              onPressed: () => setState(() => _hidden = !_hidden),
            )
          : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) FieldLabel(widget.label!),
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.maxLines > 1 ? widget.maxLines : 1,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          textCapitalization: widget.textCapitalization,
          style: TextStyle(color: context.ink, fontSize: 16),
          decoration: deco,
        ),
      ],
    );
  }
}

/// Campo que, al tocarlo, abre una lista de opciones (universidad, tipo…).
class SelectField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? errorText;
  const SelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
    this.errorText,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final o in options)
              ListTile(
                title: Text(o, style: TextStyle(color: context.ink, fontWeight: FontWeight.w600)),
                trailing: o == value
                    ? const Icon(Icons.check_rounded, color: RentiColors.blue)
                    : null,
                onTap: () => Navigator.pop(context, o),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => TappableField(
        label: label,
        text: value ?? hint,
        isHint: value == null,
        errorText: errorText,
        onTap: () => _open(context),
      );
}

/// Campo con aspecto de input pero que solo responde al toque.
class TappableField extends StatelessWidget {
  final String label;
  final String text;
  final bool isHint;
  final VoidCallback onTap;
  final String? errorText;
  const TappableField({
    super.key,
    required this.label,
    required this.text,
    required this.isHint,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: errorText == null ? context.line : Colors.redAccent,
                width: 1.5,
              ),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                color: isHint ? context.muted : context.ink,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 0, 0),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

/// Píldora seleccionable (filtros, duración, servicios…).
class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final EdgeInsets padding;
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? RentiColors.blue : context.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? RentiColors.blue : context.line,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : context.ink,
          ),
        ),
      ),
    );
  }
}

/// Fila de píldoras que salta de línea.
class PillWrap extends StatelessWidget {
  final List<String> options;
  final bool Function(String) isSelected;
  final ValueChanged<String> onTap;
  const PillWrap({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final o in options)
            PillChip(label: o, selected: isSelected(o), onTap: () => onTap(o)),
        ],
      );
}

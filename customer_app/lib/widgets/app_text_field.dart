import 'package:flutter/material.dart';

/// Themed text field. Thin wrapper over [TextFormField] using the global
/// `inputDecorationTheme`. See `docs/COMPONENT_SPEC.md` §5.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixText,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.onFieldSubmitted,
    this.textInputAction,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? prefixText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        suffixIcon: suffix,
      ),
    );
  }
}

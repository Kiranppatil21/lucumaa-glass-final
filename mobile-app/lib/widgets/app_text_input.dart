import 'package:flutter/material.dart';

/// Reusable text input for non-Form widgets (e.g. Formz-driven forms).
class AppTextInput extends StatelessWidget {
  const AppTextInput({
    super.key,
    required this.label,
    required this.onChanged,
    this.errorText,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

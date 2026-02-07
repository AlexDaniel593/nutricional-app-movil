import 'package:flutter/material.dart';
import '../atoms/custom_text_field.dart';

/// Molecule: Campo de formulario con validación de contraseña
class PasswordFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final int minLength;

  const PasswordFormField({
    super.key,
    this.controller,
    this.label,
    this.minLength = 6,
  });

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      label: widget.label ?? 'Contraseña',
      hint: '••••••••',
      prefixIcon: Icons.lock,
      suffixIcon: _obscureText ? Icons.visibility : Icons.visibility_off,
      onSuffixIconPressed: _togglePasswordVisibility,
      obscureText: _obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su contraseña';
        }
        if (value.length < widget.minLength) {
          return 'La contraseña debe tener al menos ${widget.minLength} caracteres';
        }
        return null;
      },
    );
  }
}

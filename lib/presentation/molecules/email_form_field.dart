import 'package:flutter/material.dart';
import '../atoms/custom_text_field.dart';

/// Molecule: Campo de formulario con validación de email
class EmailFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;

  const EmailFormField({
    super.key,
    this.controller,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Email',
      hint: 'ejemplo@correo.com',
      prefixIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su email';
        }
        if (!value.contains('@')) {
          return 'Por favor ingrese un email válido';
        }
        return null;
      },
    );
  }
}

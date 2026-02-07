import 'package:flutter/material.dart';
import '../atoms/custom_text_field.dart';

/// Molecule: Campo de formulario para nombre
class NameFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;

  const NameFormField({
    super.key,
    this.controller,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Nombre',
      hint: 'Ingrese su nombre',
      prefixIcon: Icons.person,
      keyboardType: TextInputType.name,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su nombre';
        }
        if (value.length < 2) {
          return 'El nombre debe tener al menos 2 caracteres';
        }
        return null;
      },
    );
  }
}

import 'package:flutter/material.dart';

class AppColors {
  // Paleta de colores principal
  static const Color dustGrey = Color(0xFFDAD7CD);
  static const Color drySage = Color(0xFFA3B18A);
  static const Color fern = Color(0xFF588157);
  static const Color hunterGreen = Color(0xFF3A5A40);
  static const Color pineTeal = Color(0xFF344E41);
  
  // Colores de estado
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
  
  // Colores de texto
  static const Color textPrimary = pineTeal;
  static const Color textSecondary = hunterGreen;
  static const Color textLight = drySage;
  static const Color textOnDark = dustGrey;
  
  // Colores de fondo
  static const Color background = dustGrey;
  static const Color surface = Colors.white;
  static const Color surfaceDark = pineTeal;
  
  // Constructor privado para prevenir instanciación
  AppColors._();
}

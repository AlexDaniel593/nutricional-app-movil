import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Atom: Botón social (Google, Facebook, etc)
class SocialButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SocialButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? AppColors.hunterGreen,
        backgroundColor: backgroundColor,
        side: BorderSide(
          color: foregroundColor ?? AppColors.hunterGreen,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}

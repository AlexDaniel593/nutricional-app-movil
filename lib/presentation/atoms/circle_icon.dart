import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Atom: Icono con fondo circular
class CircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const CircleIcon({
    super.key,
    required this.icon,
    this.size = 80,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.hunterGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: color ?? AppColors.hunterGreen,
      ),
    );
  }
}

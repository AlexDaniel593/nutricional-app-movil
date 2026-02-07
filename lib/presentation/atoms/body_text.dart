import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Atom: Texto de cuerpo
class BodyText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final Color? color;
  final FontWeight? fontWeight;

  const BodyText({
    super.key,
    required this.text,
    this.textAlign,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color ?? AppColors.textSecondary,
            fontWeight: fontWeight,
          ),
    );
  }
}

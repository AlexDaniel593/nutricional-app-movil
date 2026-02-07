import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Atom: Texto de título
class TitleText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final Color? color;

  const TitleText({
    super.key,
    required this.text,
    this.textAlign,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color ?? AppColors.textPrimary,
          ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Atom: Texto de subtítulo
class SubtitleText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final Color? color;

  const SubtitleText({
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
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color ?? AppColors.textSecondary,
          ),
    );
  }
}

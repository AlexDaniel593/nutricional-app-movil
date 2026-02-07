import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../atoms/body_text.dart';

/// Molecule: Divisor con texto
class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.drySage),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BodyText(
            text: text,
            color: AppColors.textLight,
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.drySage),
        ),
      ],
    );
  }
}

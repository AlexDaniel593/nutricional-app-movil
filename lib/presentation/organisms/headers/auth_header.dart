import 'package:flutter/material.dart';
import '../../atoms/circle_icon.dart';
import '../../atoms/title_text.dart';

/// Organism: Header de autenticación
class AuthHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const AuthHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleIcon(
          icon: icon,
          size: 100,
        ),
        const SizedBox(height: 24),
        TitleText(
          text: title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

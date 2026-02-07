import 'package:flutter/material.dart';
import '../atoms/social_button.dart';

/// Molecule: Grupo de botones sociales
class SocialButtonsGroup extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onFacebookPressed;

  const SocialButtonsGroup({
    super.key,
    this.onGooglePressed,
    this.onFacebookPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SocialButton(
            text: 'Google',
            icon: Icons.g_mobiledata,
            onPressed: onGooglePressed,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SocialButton(
            text: 'Facebook',
            icon: Icons.facebook,
            onPressed: onFacebookPressed,
            foregroundColor: const Color(0xFF1877F2),
          ),
        ),
      ],
    );
  }
}

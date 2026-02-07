import 'package:flutter/material.dart';
import '../../molecules/email_form_field.dart';
import '../../molecules/password_form_field.dart';
import '../../atoms/primary_button.dart';
import '../../molecules/social_buttons_group.dart';
import '../../molecules/divider_with_text.dart';

/// Organism: Formulario de inicio de sesión
class LoginForm extends StatefulWidget {
  final VoidCallback? onLogin;
  final VoidCallback? onGoogleLogin;
  final VoidCallback? onFacebookLogin;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;

  const LoginForm({
    super.key,
    this.onLogin,
    this.onGoogleLogin,
    this.onFacebookLogin,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    this.isLoading = false,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          EmailFormField(
            controller: widget.emailController,
          ),
          const SizedBox(height: 16),
          
          // Password field
          PasswordFormField(
            controller: widget.passwordController,
          ),
          const SizedBox(height: 24),
          
          // Login button
          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unified login button
                PrimaryButton(
                  text: 'Iniciar Sesión',
                  onPressed: widget.onLogin,
                  width: double.infinity,
                ),
                const SizedBox(height: 24),
                
                // Divider
                const DividerWithText(text: 'O inicia sesión con'),
                const SizedBox(height: 24),
                
                // Social buttons
                SocialButtonsGroup(
                  onGooglePressed: widget.onGoogleLogin,
                  onFacebookPressed: widget.onFacebookLogin,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../molecules/email_form_field.dart';
import '../../molecules/password_form_field.dart';
import '../../molecules/name_form_field.dart';
import '../../atoms/primary_button.dart';
import '../../molecules/social_buttons_group.dart';
import '../../molecules/divider_with_text.dart';

/// Organism: Formulario de registro
class RegisterForm extends StatefulWidget {
  final VoidCallback? onRegister;
  final VoidCallback? onGoogleRegister;
  final VoidCallback? onFacebookRegister;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;

  const RegisterForm({
    super.key,
    this.onRegister,
    this.onGoogleRegister,
    this.onFacebookRegister,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    this.isLoading = false,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name field
          NameFormField(
            controller: widget.nameController,
          ),
          const SizedBox(height: 16),
          
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
          
          // Register button
          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  text: 'Registrarse',
                  onPressed: widget.onRegister,
                  width: double.infinity,
                ),
                const SizedBox(height: 24),
                
                // Divider
                const DividerWithText(text: 'O regístrate con'),
                const SizedBox(height: 24),
                
                // Social buttons
                SocialButtonsGroup(
                  onGooglePressed: widget.onGoogleRegister,
                  onFacebookPressed: widget.onFacebookRegister,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

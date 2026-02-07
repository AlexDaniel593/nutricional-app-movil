import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../templates/auth_template.dart';
import '../organisms/headers/auth_header.dart';
import '../organisms/forms/register_form.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (mounted && authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted && authProvider.errorMessage != null) {
        _showErrorSnackBar(authProvider.errorMessage!);
        authProvider.clearError();
      }
    }
  }

  Future<void> _handleGoogleRegister() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loginWithGoogle();

    if (mounted && authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
      authProvider.clearError();
    }
  }

  Future<void> _handleFacebookRegister() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loginWithFacebook();

    if (mounted && authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
      authProvider.clearError();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthTemplate(
      appBarTitle: 'Crear Cuenta',
      showBackButton: true,
      child: Column(
        children: [
          const AuthHeader(
            title: 'Regístrate',
            icon: Icons.person_add,
          ),
          RegisterForm(
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            passwordController: _passwordController,
            isLoading: authProvider.isLoading,
            onRegister: _handleRegister,
            onGoogleRegister: _handleGoogleRegister,
            onFacebookRegister: _handleFacebookRegister,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('¿Ya tienes una cuenta? Inicia sesión'),
          ),
        ],
      ),
    );
  }
}

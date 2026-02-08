import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../templates/auth_template.dart';
import '../organisms/headers/auth_header.dart';
import '../organisms/forms/login_form.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.loginUnified(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted && authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted && authProvider.errorMessage != null) {
        _showErrorSnackBar(authProvider.errorMessage!);
        authProvider.clearError();
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loginWithGoogle();

    if (mounted && authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
      authProvider.clearError();
    }
  }

  Future<void> _handleFacebookLogin() async {
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
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _openTermsAndConditions() async {
    final Uri url = Uri.parse('https://nutrition-calendar-dansu.vercel.app/terms-and-conditions.html');
    try {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al abrir términos y condiciones: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthTemplate(
      appBarTitle: 'Iniciar Sesión',
      child: Column(
        children: [
          const AuthHeader(
            title: 'Bienvenido',
            icon: Icons.restaurant_menu,
          ),
          LoginForm(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            isLoading: authProvider.isLoading,
            onLogin: _handleEmailLogin,
            onGoogleLogin: _handleGoogleLogin,
            onFacebookLogin: _handleFacebookLogin,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: const Text('¿No tienes una cuenta? Regístrate'),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Al iniciar sesión, aceptas nuestros',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: _openTermsAndConditions,
            child: Text(
              'Términos y Condiciones',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.hunterGreen,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

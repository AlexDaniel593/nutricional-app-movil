import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Template: Plantilla base para pantallas de autenticación
class AuthTemplate extends StatelessWidget {
  final Widget child;
  final String? appBarTitle;
  final bool showBackButton;

  const AuthTemplate({
    super.key,
    required this.child,
    this.appBarTitle,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBarTitle != null
          ? AppBar(
              title: Text(appBarTitle!),
              automaticallyImplyLeading: showBackButton,
              backgroundColor: AppColors.hunterGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: child,
        ),
      ),
    );
  }
}

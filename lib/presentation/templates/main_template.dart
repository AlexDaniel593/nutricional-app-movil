import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Template: Plantilla base para pantallas principales
class MainTemplate extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const MainTemplate({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.hunterGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: actions,
      ),
      body: SafeArea(
        child: child,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

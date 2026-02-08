import 'package:flutter/material.dart';
/// Template: Plantilla base para pantallas de recetas
class RecipeTemplate extends StatelessWidget {
  final Widget child;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final Widget? drawer;

  const RecipeTemplate({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      appBar: AppBar(
        leading: drawer != null && !showBackButton
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        automaticallyImplyLeading: showBackButton,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: actions,
      ),
      body: SafeArea(
        child: child,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

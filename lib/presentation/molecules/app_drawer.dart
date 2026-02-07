import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Molecule: Navigation Drawer para la aplicación
class AppDrawer extends StatelessWidget {
  final String? username;
  final String? email;
  final VoidCallback? onRecipesPressed;
  final VoidCallback? onCalendarPressed;
  final VoidCallback? onProductsPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onLogoutPressed;

  const AppDrawer({
    super.key,
    this.username,
    this.email,
    this.onRecipesPressed,
    this.onCalendarPressed,
    this.onProductsPressed,
    this.onSettingsPressed,
    this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.hunterGreen,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 50,
                color: AppColors.hunterGreen,
              ),
            ),
            accountName: Text(
              username ?? 'Usuario',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Mis Recetas'),
            onTap: onRecipesPressed,
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Calendario Semanal'),
            onTap: onCalendarPressed,
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Productos'),
            onTap: onProductsPressed,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: onSettingsPressed,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: onLogoutPressed,
          ),
        ],
      ),
    );
  }
}

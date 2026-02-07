import 'package:flutter/material.dart';
import 'package:nutricional/presentation/pages/settings_screen.dart';
import 'package:provider/provider.dart';
import 'recipe_list_screen.dart';
import 'calendar_screen.dart';
import 'product_list_screen.dart';
import '../providers/auth_provider.dart';
import '../molecules/app_drawer.dart';
import '../../data/services/firebase_messaging_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Por defecto calendario
  final FirebaseMessagingService _messagingService = FirebaseMessagingService.instance;

  final List<Widget> _screens = [
    const CalendarScreen(showBottomNav: false),
    const RecipeListScreen(showBottomNav: false),
    const ProductListScreen(showBottomNav: false),
  ];

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  /// Configura los manejadores de notificaciones push
  void _setupNotifications() {
    // Configurar manejador de mensajes en primer plano
    _messagingService.configureForegroundHandler(
      context,
      (title, body) {
        debugPrint('Notificación recibida en primer plano: $title - $body');
      },
    );

    // Configurar manejador de mensajes en segundo plano
    _messagingService.configureBackgroundHandler(
      context,
      (title, body) {
        // Navegar a la página de detalle
        Navigator.pushNamed(
          context,
          '/notification-detail',
          arguments: {'title': title, 'body': body},
        );
      },
    );

    // Verificar si la app se abrió desde una notificación (app terminada)
    _messagingService.checkInitialMessage(
      context,
      (title, body) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/notification-detail',
              arguments: {'title': title, 'body': body},
            );
          }
        });
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedIndex == 0
                  ? 'Calendario Semanal'
                  : _selectedIndex == 1
                      ? 'Mis Recetas'
                      : 'Mis Productos',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              authProvider.currentUser?.username ?? authProvider.currentUser?.email ?? '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: AppDrawer(
        username: authProvider.currentUser?.username,
        email: authProvider.currentUser?.email,
        onRecipesPressed: () {
          Navigator.pop(context);
          setState(() {
            _selectedIndex = 1;
          });
        },
        onCalendarPressed: () {
          Navigator.pop(context);
          setState(() {
            _selectedIndex = 0;
          });
        },
        onProductsPressed: () {
          Navigator.pop(context);
          setState(() {
            _selectedIndex = 2;
          });
        },
        onSettingsPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
        onLogoutPressed: () async {
          Navigator.pop(context);
          await authProvider.logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recetas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
        ],
      ),
    );
  }
}

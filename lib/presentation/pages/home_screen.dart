import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'recipe_list_screen.dart';
import 'calendar_screen.dart';
import 'product_list_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/calendar_provider.dart';
import '../molecules/app_drawer.dart';
import '../atoms/smart_cached_image.dart';
import '../../data/services/firebase_messaging_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0=Home, 1=Calendar, 2=Recipes, 3=Products
  final FirebaseMessagingService _messagingService = FirebaseMessagingService.instance;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context.read<RecipeProvider>().loadRecipes(userId: authProvider.currentUser!.id);
        context.read<CalendarProvider>().loadWeekEntries(authProvider.currentUser!.id);
      }
    });
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

  Widget _buildHomePage() {
    final recipeProvider = context.watch<RecipeProvider>();
    final calendarProvider = context.watch<CalendarProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scan Product Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildScanProductCard(context),
          ),
          
          // Up Next Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildUpNextSection(calendarProvider),
          ),
          
          const SizedBox(height: 24),
          
          // My Recipes Section
          _buildMyRecipesSection(recipeProvider),
          
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildScanProductCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/scanner'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.qr_code_scanner,
                size: 140,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Escanear Producto',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Agrega productos escaneando\ncódigos de barras',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/scanner'),
                    icon: const Icon(Icons.photo_camera, size: 20),
                    label: const Text('Escanear Ahora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpNextSection(CalendarProvider calendarProvider) {
    final now = DateTime.now();
    final upcomingEntries = calendarProvider.entries.where((entry) {
      return entry.scheduledDate.isAfter(now);
    }).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedIndex = 1);
              },
              child: const Text('Ver Calendario'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcomingEntries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay comidas programadas',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: upcomingEntries.first.recipeImageUrl.isNotEmpty
                        ? SmartCachedImage(
                            imageUrl: upcomingEntries.first.recipeImageUrl,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 96,
                            height: 96,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.restaurant, size: 40),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getMealTypeColor(upcomingEntries.first.mealType),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getMealTypeName(upcomingEntries.first.mealType),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('HH:mm').format(upcomingEntries.first.scheduledDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          upcomingEntries.first.recipeTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() => _selectedIndex = 1);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMyRecipesSection(RecipeProvider recipeProvider) {
    final recipes = recipeProvider.recipes.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Recetas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/recipes');
                },
                child: const Text('Ver Todas'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No tienes recetas todavía',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/recipe-form'),
                        child: const Text('Crear tu primera receta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/recipe-detail',
                      arguments: {
                        "name": recipe.title,
                        "description": recipe.description,
                        "uid": recipe.id,
                        "image": recipe.imageUrl,
                        "recipe": recipe,
                      },
                    );
                  },
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: recipe.imageUrl.isNotEmpty
                              ? SmartCachedImage(
                                  imageUrl: recipe.imageUrl,
                                  width: 200,
                                  height: 280,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 200,
                                  height: 280,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.restaurant, size: 60),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.9),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recipe.category,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _getMealTypeName(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Desayuno';
      case 'lunch':
        return 'Almuerzo';
      case 'dinner':
        return 'Cena';
      case 'snack':
        return 'Snack';
      default:
        return mealType;
    }
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.blue;
      case 'dinner':
        return Colors.purple;
      case 'snack':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    Widget body;
    String title;
    Widget? fab;

    switch (_selectedIndex) {
      case 0: // Home
        body = _buildHomePage();
        title = 'Inicio';
        fab = FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/recipe-form'),
          icon: const Icon(Icons.add),
          label: const Text('Crear Receta'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        );
        break;
      case 1: // Calendar
        body = const CalendarScreen(showBottomNav: false);
        title = 'Calendario Semanal';
        fab = null;
        break;
      case 2: // Recipes
        body = const RecipeListScreen(showBottomNav: false);
        title = 'Mis Recetas';
        fab = FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/recipe-form'),
          child: const Icon(Icons.add),
        );
        break;
      case 3: // Products
        body = const ProductListScreen(showBottomNav: false);
        title = 'Mis Productos';
        fab = null;
        break;
      default:
        body = _buildHomePage();
        title = 'Inicio';
        fab = null;
    }

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
              title,
              style: const TextStyle(fontSize: 18),
            ),
            if (_selectedIndex == 0)
              Text(
                'Hola, ${authProvider.currentUser?.username ?? authProvider.currentUser?.email ?? "Usuario"}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ]
            : null,
      ),
      drawer: AppDrawer(
        username: authProvider.currentUser?.username,
        email: authProvider.currentUser?.email,
        onHomePressed: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 0);
        },
        onRecipesPressed: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 2);
        },
        onCalendarPressed: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 1);
        },
        onProductsPressed: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 3);
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
      body: SafeArea(child: body),
      floatingActionButton: fab,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Recetas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
        ],
      ),
    );
  }
}

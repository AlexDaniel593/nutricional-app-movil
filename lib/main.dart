import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/recipe_provider.dart';
import 'presentation/providers/calendar_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/pages/login_screen.dart';
import 'presentation/pages/register_screen.dart';
import 'presentation/pages/home_screen.dart';
import 'presentation/pages/recipe_list_screen.dart';
import 'presentation/pages/recipe_form_screen.dart';
import 'presentation/pages/recipe_detail_screen.dart';
import 'presentation/pages/calendar_screen.dart';
import 'presentation/pages/product_list_screen.dart';
import 'presentation/pages/product_detail_screen.dart';
import 'presentation/pages/scanner_screen.dart';
import 'presentation/pages/notification_detail_page.dart';
import 'presentation/pages/introduction_page.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/firebase_messaging_service.dart';
import 'data/datasources/local/database_helper.dart';
import 'data/datasources/local/product_local_datasource.dart';
import 'data/datasources/product_firebase_datasource.dart';
import 'data/repositories/product_repository_impl.dart';
import 'data/services/open_food_facts_service.dart';
import 'domain/usecases/create_product.dart';
import 'domain/usecases/get_products.dart';
import 'domain/usecases/update_product.dart';
import 'domain/usecases/delete_product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar datos de localización
  await initializeDateFormatting('es', null);
  
  // Inicializar servicio de conectividad
  await ConnectivityService.instance.initialize();
  
  // Configurar manejador de mensajes en segundo plano (app cerrada)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Inicializar Firebase Messaging
  await FirebaseMessagingService.instance.initialize();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializar dependencias para ProductProvider
    final dbHelper = DatabaseHelper.instance;
    final productLocalDatasource = ProductLocalDatasource(dbHelper);
    final productFirebaseDatasource = ProductFirebaseDatasource();
    final productRepository = ProductRepositoryImpl(
      productLocalDatasource,
      productFirebaseDatasource,
    );
    final openFoodFactsService = OpenFoodFactsService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(
            createProduct: CreateProduct(productRepository),
            getProducts: GetProducts(productRepository),
            updateProduct: UpdateProduct(productRepository),
            deleteProduct: DeleteProduct(productRepository),
            openFoodFactsService: openFoodFactsService,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          if (themeProvider.isLoading) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Nutricional',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthGate(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/recipes': (context) => const RecipeListScreen(),
              '/calendar': (context) => const CalendarScreen(),
              '/products': (context) => const ProductListScreen(),
              '/product-detail': (context) => const ProductDetailScreen(),
              '/scanner': (context) => const ScannerScreen(),
              '/recipe-form': (context) => const RecipeFormScreen(),
              '/recipe-detail': (context) => const RecipeDetailScreen(),
              '/introduction': (context) => const IntroductionPage(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/notification-detail') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => NotificationDetailPage(
                    title: args?['title'] ?? 'Notificación',
                    body: args?['body'] ?? '',
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

/// Widget que decide qué pantalla mostrar según el estado de autenticación
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isCheckingIntro = true;
  bool _introCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkIntroduction();
  }

  Future<void> _checkIntroduction() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('introduction_completed') ?? false;
    setState(() {
      _introCompleted = completed;
      _isCheckingIntro = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Verificando si se completó la introducción
    if (_isCheckingIntro) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si no se ha completado la introducción, mostrarla
    if (!_introCompleted) {
      return const IntroductionPage();
    }

    // Mientras verifica la sesión, mostrar splash
    if (authProvider.isCheckingSession) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando sesión...'),
            ],
          ),
        ),
      );
    }

    // Si hay usuario autenticado, ir a home
    if (authProvider.isAuthenticated) {
      // Usar Future.microtask para evitar rebuild durante build
      Future.microtask(() {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si no hay sesión, mostrar login
    return const LoginScreen();
  }
}


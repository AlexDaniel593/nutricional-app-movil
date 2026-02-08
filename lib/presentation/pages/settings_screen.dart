import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/product_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/theme_provider.dart';
import '../../data/datasources/recipe_firebase_datasource.dart';
import '../../data/datasources/product_firebase_datasource.dart';
import '../../data/datasources/calendar_firebase_datasource.dart';
import '../../data/datasources/cloudinary_datasource.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _generateUserDataPDF(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    final productProvider = context.read<ProductProvider>();
    final calendarProvider = context.read<CalendarProvider>();

    if (authProvider.currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay usuario autenticado')),
        );
      }
      return;
    }

    final user = authProvider.currentUser!;

    // Mostrar indicador de carga
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Crear el PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Reporte de Datos del Usuario',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Información del Usuario
              pw.Header(
                level: 1,
                child: pw.Text('Información Personal'),
              ),
              pw.Table.fromTextArray(
                data: [
                  ['Nombre', user.username],
                  ['Email', user.email],
                  ['ID', user.id],
                ],
              ),
              pw.SizedBox(height: 20),

              // Recetas
              pw.Header(
                level: 1,
                child: pw.Text('Mis Recetas (${recipeProvider.recipes.length})'),
              ),
              if (recipeProvider.recipes.isEmpty)
                pw.Text('No tienes recetas guardadas')
              else
                pw.Table.fromTextArray(
                  headers: ['Título', 'Descripción', 'Tiempo', 'Porciones'],
                  data: recipeProvider.recipes.map((recipe) => [
                    recipe.title,
                    recipe.description.length > 50 
                        ? '${recipe.description.substring(0, 50)}...' 
                        : recipe.description,
                    '${recipe.preparationTime} min',
                    '${recipe.servings}',
                  ]).toList(),
                ),
              pw.SizedBox(height: 20),

              // Productos
              pw.Header(
                level: 1,
                child: pw.Text('Mis Productos (${productProvider.products.length})'),
              ),
              if (productProvider.products.isEmpty)
                pw.Text('No tienes productos guardados')
              else
                pw.Table.fromTextArray(
                  headers: ['Nombre', 'Marca', 'Código', 'Calorías'],
                  data: productProvider.products.map((product) => [
                    product.name,
                    product.brand,
                    product.barcode,
                    '${product.nutritionalInfo.calories.toStringAsFixed(0)} kcal',
                  ]).toList(),
                ),
              pw.SizedBox(height: 20),

              // Calendario
              pw.Header(
                level: 1,
                child: pw.Text('Entradas de Calendario (${calendarProvider.entries.length})'),
              ),
              if (calendarProvider.entries.isEmpty)
                pw.Text('No tienes entradas en el calendario')
              else
                pw.Table.fromTextArray(
                  headers: ['Receta', 'Fecha', 'Tipo de Comida'],
                  data: calendarProvider.entries.map((entry) => [
                    entry.recipeTitle,
                    '${entry.scheduledDate.day}/${entry.scheduledDate.month}/${entry.scheduledDate.year}',
                    _getMealTypeName(entry.mealType),
                  ]).toList(),
                ),

              pw.SizedBox(height: 40),
              pw.Text(
                'Reporte generado el ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ];
          },
        ),
      );

      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar el PDF para imprimir o guardar
      if (context.mounted) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'datos_usuario_${user.username}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
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

  void _showSupportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.green),
            SizedBox(width: 8),
            Text('Soporte'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Necesitas ayuda?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contáctanos a través de nuestro correo electrónico:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'dalexis203@gmail.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.hunterGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDataDeletionPolicy(BuildContext context) async {
    final Uri url = Uri.parse('https://nutrition-calendar-dansu.vercel.app/data-deletion-policy.html');
    try {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir política: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción es irreversible. Se eliminarán:\n\n'
              '• Tu cuenta de usuario\n'
              '• Todas tus recetas\n'
              '• Todos tus productos\n'
              '• Todo tu calendario\n'
              '• Toda tu información personal\n'
              '• Todas tus imágenes de Cloudinary\n\n'
              '¿Estás seguro de que deseas continuar?',
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _openDataDeletionPolicy(context),
              child: Text(
                'Ver política de eliminación de datos',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.hunterGreen,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Cuenta'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAccount(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay usuario autenticado')),
        );
      }
      return;
    }

    final userId = authProvider.currentUser!.id;

    // Mostrar indicador de carga
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Eliminando cuenta...'),
            ],
          ),
        ),
      );
    }

    try {
      // Inicializar datasources
      final recipeFirebase = RecipeFirebaseDatasource();
      final productFirebase = ProductFirebaseDatasource();
      final calendarFirebase = CalendarFirebaseDatasource();
      final cloudinaryDatasource = CloudinaryDatasource();

      // Obtener todas las recetas para eliminar sus imágenes
      final recipes = await recipeFirebase.getRecipesByUser(userId);
      
      // Eliminar imágenes de Cloudinary de las recetas
      for (final recipe in recipes) {
        if (recipe.imageUrl.isNotEmpty) {
          try {
            await cloudinaryDatasource.deleteImageByUrl(recipe.imageUrl);
          } catch (e) {
            // Continuar aunque falle la eliminación de una imagen
            print('Error al eliminar imagen de receta ${recipe.id}: $e');
          }
        }
        // Eliminar la receta de Firebase
        await recipeFirebase.deleteRecipe(recipe.id);
      }

      // Obtener todos los productos para eliminar sus imágenes
      final products = await productFirebase.getProductsByUser(userId);
      
      // Eliminar imágenes de Cloudinary de los productos
      for (final product in products) {
        if (product.imageUrl.isNotEmpty) {
          try {
            await cloudinaryDatasource.deleteImageByUrl(product.imageUrl);
          } catch (e) {
            // Continuar aunque falle la eliminación de una imagen
            print('Error al eliminar imagen de producto ${product.id}: $e');
          }
        }
        // Eliminar el producto de Firebase
        await productFirebase.deleteProduct(product.id);
      }

      // Eliminar todas las entradas del calendario
      final calendarEntries = await calendarFirebase.getEntriesByUser(userId);
      for (final entry in calendarEntries) {
        await calendarFirebase.deleteEntry(entry.id);
      }

      // Eliminar cuenta de Firebase Auth
      await authProvider.deleteAccount();
      
      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a la pantalla de login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cuenta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Información del usuario
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuenta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.currentUser?.username ?? 'Usuario',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              authProvider.currentUser?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preferencias
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.orange,
                  ),
                  title: const Text('Modo oscuro'),
                  subtitle: Text(
                    themeProvider.isDarkMode ? 'Activado' : 'Desactivado',
                  ),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) async {
                      await themeProvider.toggleTheme();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Opciones
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.blue),
                  title: const Text('Descargar mis datos'),
                  subtitle: const Text('Generar PDF con toda tu información'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _generateUserDataPDF(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.green),
                  title: const Text('Soporte'),
                  subtitle: const Text('Contacta con nuestro equipo de soporte'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showSupportModal(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Eliminar cuenta',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Eliminar permanentemente tu cuenta y datos'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Información adicional
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Al descargar tus datos, se generará un PDF con toda la información almacenada en tu cuenta.\n\n'
              'Al eliminar tu cuenta, se borrarán permanentemente todos los datos asociados a tu usuario. Esta acción no se puede deshacer.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

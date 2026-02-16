import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import 'settings_screen.dart';
import '../providers/calendar_provider.dart';
import '../providers/recipe_provider.dart';
import '../templates/recipe_template.dart';
import '../molecules/app_drawer.dart';
import '../atoms/smart_cached_image.dart';
import '../../domain/entities/recipe.dart';

class CalendarScreen extends StatefulWidget {
  final bool showBottomNav;
  
  const CalendarScreen({super.key, this.showBottomNav = true});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final calendarProvider = context.read<CalendarProvider>();
      
      if (authProvider.currentUser != null) {
        calendarProvider.loadWeekEntries(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    final authProvider = context.watch<AuthProvider>();
    final weekDays = calendarProvider.getWeekDays();

    final content = Column(
      children: [
        // Controles de navegación de semana
        _buildWeekNavigation(calendarProvider, authProvider),
        
        // Tabla de calendario
        Expanded(
          child: calendarProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Encabezado fijo
                    _buildCalendarHeader(),
                    // Cuerpo scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildCalendarBody(weekDays, calendarProvider, authProvider),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );

    // Si no se muestra bottom nav, solo retornar el contenido
    if (!widget.showBottomNav) {
      return Scaffold(
        body: SafeArea(child: content),
      );
    }

    return RecipeTemplate(
      title: 'Calendario Semanal',
      subtitle: authProvider.currentUser?.username ?? authProvider.currentUser?.email ?? '',
      showBackButton: false,
      drawer: widget.showBottomNav ? AppDrawer(
        username: authProvider.currentUser?.username,
        email: authProvider.currentUser?.email,
        onHomePressed: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/home');
        },
        onRecipesPressed: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/recipes');
        },
        onCalendarPressed: () {
          Navigator.pop(context);
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
      ) : null,
      child: content,
    );
  }

  Widget _buildWeekNavigation(CalendarProvider calendarProvider, AuthProvider authProvider) {
    final startDate = calendarProvider.selectedWeekStart;
    final endDate = startDate.add(const Duration(days: 6));
    final dateFormat = DateFormat('dd MMM', 'es');

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              if (authProvider.currentUser != null) {
                calendarProvider.previousWeek(authProvider.currentUser!.id);
              }
            },
          ),
          Column(
            children: [
              Text(
                '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.today, size: 16),
                label: const Text('Hoy'),
                onPressed: () {
                  if (authProvider.currentUser != null) {
                    calendarProvider.goToCurrentWeek(authProvider.currentUser!.id);
                  }
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              if (authProvider.currentUser != null) {
                calendarProvider.nextWeek(authProvider.currentUser!.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      height: 60,
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                'Día',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ..._mealTypes.map((mealType) => Expanded(
            child: Center(
              child: Text(
                _getMealTypeName(mealType),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).colorScheme.onPrimaryContainer),
                textAlign: TextAlign.center,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCalendarBody(
    List<DateTime> weekDays,
    CalendarProvider calendarProvider,
    AuthProvider authProvider,
  ) {
    const cellHeight = 120.0;

    return Column(
      children: weekDays.map((day) {
        return Container(
          height: cellHeight,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE', 'es').format(day),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      DateFormat('dd/MM', 'es').format(day),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              ..._mealTypes.map((mealType) {
                final mealEntry = calendarProvider.getEntryForDayAndMeal(day, mealType);
                return Expanded(
                  child: _buildMealCell(day, mealType, mealEntry, calendarProvider, authProvider),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMealCell(
    DateTime day,
    String mealType,
    dynamic entry,
    CalendarProvider calendarProvider,
    AuthProvider authProvider,
  ) {
    if (entry == null) {
      return InkWell(
        onTap: () => _showRecipeSelector(day, mealType, authProvider, calendarProvider),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _showEntryOptions(entry, authProvider, calendarProvider),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
          image: entry.recipeImageUrl.isNotEmpty
              ? DecorationImage(
                  image: SmartCachedImage.getImageProvider(entry.recipeImageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                entry.recipeTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  shadows: [Shadow(blurRadius: 2)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat('HH:mm').format(entry.scheduledDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  shadows: [Shadow(blurRadius: 2)],
                ),
              ),
            ],
          ),
        ),
      ),
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

  Future<void> _showRecipeSelector(
    DateTime day,
    String mealType,
    AuthProvider authProvider,
    CalendarProvider calendarProvider,
  ) async {
    // Obtener provider antes del async gap
    final recipeProvider = context.read<RecipeProvider>();
    
    // Cargar recetas si aún no están cargadas
    if (recipeProvider.recipes.isEmpty && authProvider.currentUser != null) {
      await recipeProvider.loadRecipes(userId: authProvider.currentUser!.id);
    }

    if (!mounted) return;

    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar receta para ${_getMealTypeName(mealType)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recipeProvider.recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipeProvider.recipes[index];
              return ListTile(
                leading: recipe.imageUrl.isNotEmpty
                    ? SmartCachedImage(
                        imageUrl: recipe.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 50,
                          height: 50,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.restaurant,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.restaurant,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                title: Text(recipe.title),
                subtitle: Text(recipe.description, maxLines: 1),
                onTap: () => Navigator.pop(context, recipe),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (selectedRecipe != null && authProvider.currentUser != null) {
      // Seleccionar hora
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: 12, minute: 0),
      );

      if (time != null) {
        final scheduledDate = DateTime(
          day.year,
          day.month,
          day.day,
          time.hour,
          time.minute,
        );

        await calendarProvider.addEntry(
          userId: authProvider.currentUser!.id,
          recipeId: selectedRecipe.id,
          recipeTitle: selectedRecipe.title,
          recipeImageUrl: selectedRecipe.imageUrl,
          scheduledDate: scheduledDate,
          mealType: mealType,
        );
        
        // Redirigir al home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  Future<void> _showEntryOptions(
    dynamic entry,
    AuthProvider authProvider,
    CalendarProvider calendarProvider,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.recipeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hora: ${DateFormat('HH:mm').format(entry.scheduledDate)}'),
            Text('Tipo: ${_getMealTypeName(entry.mealType)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'view'),
            child: const Text('Visualizar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (result == 'delete' && authProvider.currentUser != null) {
      await calendarProvider.removeEntry(entry.id, authProvider.currentUser!.id);
      
      // Redirigir al home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else if (result == 'view' && mounted) {
      // Cargar la receta completa y navegar al detalle
      final recipeProvider = context.read<RecipeProvider>();
      
      // Buscar la receta en la lista cargada
      Recipe? recipe = recipeProvider.recipes.firstWhere(
        (r) => r.id == entry.recipeId,
        orElse: () => Recipe(
          id: entry.recipeId,
          title: entry.recipeTitle,
          description: '',
          imageUrl: entry.recipeImageUrl,
          ingredients: [],
          steps: [],
          userId: entry.userId,
          createdAt: DateTime.now(),
          preparationTime: 0,
          servings: 1,
          category: '',
        ),
      );

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/recipe-detail',
          arguments: {'recipe': recipe},
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/recipe_provider.dart';
import '../../domain/entities/recipe.dart';
import '../templates/recipe_template.dart';
import '../organisms/lists/recipe_list_view.dart';
import '../atoms/connectivity_indicator.dart';
import '../molecules/sync_banner.dart';
import '../molecules/app_drawer.dart';

class RecipeListScreen extends StatefulWidget {
  final bool showBottomNav;
  
  const RecipeListScreen({super.key, this.showBottomNav = true});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final recipeProvider = context.read<RecipeProvider>();
      
      if (authProvider.currentUser != null) {
        recipeProvider.loadRecipes(userId: authProvider.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _getFilteredRecipes(List<Recipe> recipes) {
    var filtered = recipes.where((recipe) {
      final matchesSearch = recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recipe.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todas' || recipe.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
    return filtered;
  }

  Set<String> _getCategories(List<Recipe> recipes) {
    final categories = recipes.map((recipe) => recipe.category).toSet();
    return {'Todas', ...categories};
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final filteredRecipes = _getFilteredRecipes(recipeProvider.recipes);
    final categories = _getCategories(recipeProvider.recipes);

    final content = Column(
      children: [
        const SyncBanner(),
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar recetas...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        // Filtro de categorías
        if (categories.length > 1)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories.elementAt(index);
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: recipeProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron recetas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RecipeListView(
                      recipes: filteredRecipes,
                      onRecipeTap: (recipe) {
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
                      onRefresh: authProvider.currentUser != null
                          ? () async {
                              await recipeProvider.loadRecipes(
                                userId: authProvider.currentUser!.id,
                              );
                            }
                          : null,
                    ),
        ),
      ],
    );

    // Si no se muestra bottom nav, solo retornar el contenido
    if (!widget.showBottomNav) {
      return Scaffold(
        body: SafeArea(child: content),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/recipe-form');
          },
          child: const Icon(Icons.add),
        ),
      );
    }

    return RecipeTemplate(
      title: 'Mis Recetas',
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
        },
        onCalendarPressed: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/calendar');
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
      actions: [
        const ConnectivityIndicator(),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/recipe-form');
        },
        child: const Icon(Icons.add),
      ),
      child: content,
    );
  }
}

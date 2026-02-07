import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/recipe_provider.dart';
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
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final authProvider = context.watch<AuthProvider>();

    final content = Column(
      children: [
        const SyncBanner(),
        Expanded(
          child: recipeProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RecipeListView(
                  recipes: recipeProvider.recipes,
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
        backgroundColor: const Color(0xFFF5F5F5),
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

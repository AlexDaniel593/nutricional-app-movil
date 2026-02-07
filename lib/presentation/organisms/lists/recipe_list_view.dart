import 'package:flutter/material.dart';
import '../../../domain/entities/recipe.dart';
import '../recipe/recipe_card.dart';

/// Organism: Lista de recetas
class RecipeListView extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe) onRecipeTap;
  final Future<void> Function()? onRefresh;

  const RecipeListView({
    super.key,
    required this.recipes,
    required this.onRecipeTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay recetas todavía',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para agregar una',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final content = ListView.builder(
      itemCount: recipes.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return RecipeCard(
          recipe: recipe,
          onTap: () => onRecipeTap(recipe),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return content;
  }
}

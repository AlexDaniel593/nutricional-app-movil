import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/recipe.dart';
import '../templates/recipe_template.dart';
import '../organisms/headers/recipe_detail_header.dart';
import '../organisms/recipe/recipe_info_section.dart';
import '../organisms/recipe/recipe_ingredients_section.dart';
import '../organisms/recipe/recipe_steps_section.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final recipe = args['recipe'] as Recipe;
    final authProvider = context.watch<AuthProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    final isOwner = authProvider.currentUser?.id == recipe.userId;

    return RecipeTemplate(
      title: recipe.title,
      actions: isOwner
          ? [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/recipe-form',
                    arguments: recipe,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar Receta'),
                      content: const Text('¿Estás seguro de que deseas eliminar esta receta?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await recipeProvider.removeRecipe(recipe.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ]
          : null,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipeDetailHeader(recipe: recipe),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecipeInfoSection(recipe: recipe),
                  const SizedBox(height: 24),
                  RecipeIngredientsSection(ingredients: recipe.ingredients),
                  const SizedBox(height: 24),
                  RecipeStepsSection(steps: recipe.steps),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

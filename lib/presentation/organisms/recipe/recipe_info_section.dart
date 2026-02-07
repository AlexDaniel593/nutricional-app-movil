import 'package:flutter/material.dart';
import '../../../domain/entities/recipe.dart';

/// Organism: Información básica de la receta
class RecipeInfoSection extends StatelessWidget {
  final Recipe recipe;

  const RecipeInfoSection({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          recipe.description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (recipe.preparationTime > 0)
              Chip(
                avatar: const Icon(Icons.timer, size: 18),
                label: Text('${recipe.preparationTime} min'),
              ),
            if (recipe.servings > 0)
              Chip(
                avatar: const Icon(Icons.people, size: 18),
                label: Text('${recipe.servings} porción${recipe.servings > 1 ? 'es' : ''}'),
              ),
            if (recipe.category.isNotEmpty)
              Chip(
                avatar: const Icon(Icons.category, size: 18),
                label: Text(recipe.category),
              ),
          ],
        ),
      ],
    );
  }
}

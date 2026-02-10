import 'package:flutter/material.dart';
import '../../../domain/entities/recipe.dart';
import '../../atoms/smart_cached_image.dart';

/// Organism: Header de detalle de receta con imagen
class RecipeDetailHeader extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailHeader({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return recipe.imageUrl.isNotEmpty
        ? SmartCachedImage(
            imageUrl: recipe.imageUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            errorWidget: Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.restaurant,
                size: 64,
                color: Colors.grey,
              ),
            ),
          );
  }
}

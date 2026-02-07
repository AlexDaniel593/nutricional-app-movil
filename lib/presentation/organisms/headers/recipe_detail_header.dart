import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/recipe.dart';

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
        ? CachedNetworkImage(
            imageUrl: recipe.imageUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Organism: Selector de imagen para recetas
class RecipeImagePicker extends StatelessWidget {
  final File? imageFile;
  final String? existingImageUrl;
  final VoidCallback onPickImage;

  const RecipeImagePicker({
    super.key,
    this.imageFile,
    this.existingImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          imageFile!,
          fit: BoxFit.cover,
        ),
      );
    }

    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: existingImageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(color: Colors.grey[400]),
          ),
          errorWidget: (context, url, error) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('Error al cargar imagen', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text('Toca para seleccionar imagen', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}

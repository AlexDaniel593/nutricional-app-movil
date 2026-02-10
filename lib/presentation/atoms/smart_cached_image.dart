import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Atom: Widget inteligente para cargar imágenes.
/// En modo online, primero intenta leer de la caché local (cached_network_image)
/// y si no está en caché, descarga de la red (API/Cloudinary).
/// Si la URL es una ruta local (archivo), usa Image.file.
class SmartCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  /// Determina si la URL es una ruta de archivo local
  static bool isLocalPath(String url) {
    return url.startsWith('/') ||
        url.startsWith('file://') ||
        (url.length > 1 && url[1] == ':'); // Windows path (C:\...)
  }

  /// Determina si la URL es una URL de red válida
  static bool isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Retorna un ImageProvider inteligente para usar en DecorationImage, etc.
  /// Primero intenta desde caché (CachedNetworkImageProvider), si es URL de red.
  /// Si es ruta local, retorna FileImage.
  static ImageProvider getImageProvider(String imageUrl) {
    if (isNetworkUrl(imageUrl)) {
      return CachedNetworkImageProvider(imageUrl);
    } else if (isLocalPath(imageUrl)) {
      return FileImage(File(imageUrl));
    }
    // Fallback: intentar como URL de red
    return CachedNetworkImageProvider(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder = placeholder ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );

    final defaultErrorWidget = errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );

    // Si es una ruta local, intentar cargar desde archivo
    if (isLocalPath(imageUrl)) {
      final file = File(imageUrl.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => defaultErrorWidget,
        );
      }
      return defaultErrorWidget;
    }

    // Para URLs de red: CachedNetworkImage lee primero de caché,
    // si no está en caché descarga de la API
    if (isNetworkUrl(imageUrl)) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => defaultPlaceholder,
        errorWidget: (context, url, error) => defaultErrorWidget,
      );
    }

    // Fallback: intentar como CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => defaultPlaceholder,
      errorWidget: (context, url, error) => defaultErrorWidget,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';

/// Atom: Indicador de estado de conectividad
class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();

    if (recipeProvider.isOnline && recipeProvider.pendingSyncCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: recipeProvider.isOnline 
            ? Colors.orange.withValues(alpha: 0.9)
            : Colors.grey.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            recipeProvider.isOnline 
                ? Icons.sync 
                : Icons.cloud_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            recipeProvider.isOnline
                ? 'Sincronizando... (${recipeProvider.pendingSyncCount})'
                : 'Sin conexión',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

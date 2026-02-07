import 'package:flutter/material.dart';

/// Organism: Sección de ingredientes del formulario de receta
class RecipeIngredientsFormSection extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const RecipeIngredientsFormSection({
    super.key,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Ingredientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...controllers.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Ingrediente ${entry.key + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => onRemove(entry.key),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

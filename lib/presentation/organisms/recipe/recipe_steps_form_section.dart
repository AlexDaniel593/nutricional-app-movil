import 'package:flutter/material.dart';

/// Organism: Sección de pasos del formulario de receta
class RecipeStepsFormSection extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const RecipeStepsFormSection({
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
            const Text('Pasos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Paso ${entry.key + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => onRemove(entry.key),
                ),
              ],
            ),
          );
        })
      ],
    );
  }
}

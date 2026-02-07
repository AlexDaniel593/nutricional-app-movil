import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/recipe.dart';

class RecipeFirebaseDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'recipes';

  // Crear receta
  Future<Recipe> createRecipe(Recipe recipe) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'title': recipe.title,
        'description': recipe.description,
        'imageUrl': recipe.imageUrl,
        'ingredients': recipe.ingredients,
        'steps': recipe.steps,
        'userId': recipe.userId,
        'createdAt': Timestamp.fromDate(recipe.createdAt),
        'preparationTime': recipe.preparationTime,
        'servings': recipe.servings,
        'category': recipe.category,
      });

      return Recipe(
        id: docRef.id,
        title: recipe.title,
        description: recipe.description,
        imageUrl: recipe.imageUrl,
        ingredients: recipe.ingredients,
        steps: recipe.steps,
        userId: recipe.userId,
        createdAt: recipe.createdAt,
        preparationTime: recipe.preparationTime,
        servings: recipe.servings,
        category: recipe.category,
      );
    } catch (e) {
      throw Exception('Error al crear receta: ${e.toString()}');
    }
  }

  // Obtener recetas por usuario
  Future<List<Recipe>> getRecipesByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final recipes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          ingredients: List<String>.from(data['ingredients'] ?? []),
          steps: List<String>.from(data['steps'] ?? []),
          userId: data['userId'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          preparationTime: data['preparationTime'] ?? 0,
          servings: data['servings'] ?? 1,
          category: data['category'] ?? '',
        );
      }).toList();

      // Ordenar en memoria
      recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return recipes;
    } catch (e) {
      throw Exception('Error al obtener recetas: ${e.toString()}');
    }
  }

  // Obtener todas las recetas
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          ingredients: List<String>.from(data['ingredients'] ?? []),
          steps: List<String>.from(data['steps'] ?? []),
          userId: data['userId'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          preparationTime: data['preparationTime'] ?? 0,
          servings: data['servings'] ?? 1,
          category: data['category'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener recetas: ${e.toString()}');
    }
  }

  // Obtener receta por ID
  Future<Recipe> getRecipeById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) throw Exception('Receta no encontrada');

      final data = doc.data()!;
      return Recipe(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        ingredients: List<String>.from(data['ingredients'] ?? []),
        steps: List<String>.from(data['steps'] ?? []),
        userId: data['userId'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        preparationTime: data['preparationTime'] ?? 0,
        servings: data['servings'] ?? 1,
        category: data['category'] ?? '',
      );
    } catch (e) {
      throw Exception('Error al obtener receta: ${e.toString()}');
    }
  }

  // Actualizar receta
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _firestore.collection(_collection).doc(recipe.id).update({
        'title': recipe.title,
        'description': recipe.description,
        'imageUrl': recipe.imageUrl,
        'ingredients': recipe.ingredients,
        'steps': recipe.steps,
        'preparationTime': recipe.preparationTime,
        'servings': recipe.servings,
        'category': recipe.category,
      });
    } catch (e) {
      throw Exception('Error al actualizar receta: ${e.toString()}');
    }
  }

  // Eliminar receta
  Future<void> deleteRecipe(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar receta: ${e.toString()}');
    }
  }
}

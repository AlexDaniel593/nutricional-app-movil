import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/recipe.dart';
import 'database_helper.dart';

/// Datasource local para recetas usando SQLite
class RecipeLocalDatasource {
  final DatabaseHelper _dbHelper;

  RecipeLocalDatasource(this._dbHelper);

  /// Convierte una receta a Map para SQLite
  Map<String, dynamic> _recipeToMap(Recipe recipe, {bool synced = false}) {
    return {
      'id': recipe.id,
      'title': recipe.title,
      'description': recipe.description,
      'imageUrl': recipe.imageUrl,
      'ingredients': jsonEncode(recipe.ingredients),
      'steps': jsonEncode(recipe.steps),
      'userId': recipe.userId,
      'createdAt': recipe.createdAt.toIso8601String(),
      'preparationTime': recipe.preparationTime,
      'servings': recipe.servings,
      'category': recipe.category,
      'synced': synced ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
      'deleted': 0,
    };
  }

  /// Convierte un Map de SQLite a Recipe
  Recipe _mapToRecipe(Map<String, dynamic> data) {
    return Recipe(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      imageUrl: data['imageUrl'] as String,
      ingredients: List<String>.from(jsonDecode(data['ingredients'] as String)),
      steps: List<String>.from(jsonDecode(data['steps'] as String)),
      userId: data['userId'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      preparationTime: data['preparationTime'] as int,
      servings: data['servings'] as int,
      category: data['category'] as String,
    );
  }

  /// Inserta o actualiza una receta
  Future<void> saveRecipe(Recipe recipe, {bool synced = false}) async {
    final db = await _dbHelper.database;
    await db.insert(
      'recipes',
      _recipeToMap(recipe, synced: synced),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene una receta por ID
  Future<Recipe?> getRecipeById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'recipes',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _mapToRecipe(results.first);
  }

  /// Obtiene todas las recetas de un usuario
  Future<List<Recipe>> getRecipesByUser(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'recipes',
      where: 'userId = ? AND deleted = 0',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return results.map(_mapToRecipe).toList();
  }

  /// Obtiene todas las recetas
  Future<List<Recipe>> getAllRecipes() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'recipes',
      where: 'deleted = 0',
      orderBy: 'createdAt DESC',
    );

    return results.map(_mapToRecipe).toList();
  }

  /// Actualiza una receta
  Future<void> updateRecipe(Recipe recipe) async {
    final db = await _dbHelper.database;
    await db.update(
      'recipes',
      {
        'title': recipe.title,
        'description': recipe.description,
        'imageUrl': recipe.imageUrl,
        'ingredients': jsonEncode(recipe.ingredients),
        'steps': jsonEncode(recipe.steps),
        'preparationTime': recipe.preparationTime,
        'servings': recipe.servings,
        'category': recipe.category,
        'updatedAt': DateTime.now().toIso8601String(),
        'synced': 0, // Marcar como no sincronizado
      },
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  /// Elimina una receta (soft delete)
  Future<void> deleteRecipe(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'recipes',
      {
        'deleted': 1,
        'synced': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina una receta permanentemente
  Future<void> hardDeleteRecipe(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene recetas no sincronizadas
  Future<List<Recipe>> getUnsyncedRecipes() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'recipes',
      where: 'synced = 0 AND deleted = 0',
      orderBy: 'updatedAt ASC',
    );

    return results.map(_mapToRecipe).toList();
  }

  /// Obtiene recetas eliminadas no sincronizadas
  Future<List<String>> getDeletedUnsyncedRecipeIds() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'recipes',
      columns: ['id'],
      where: 'deleted = 1 AND synced = 0',
    );

    return results.map((r) => r['id'] as String).toList();
  }

  /// Marca una receta como sincronizada
  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'recipes',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Guarda múltiples recetas desde la nube
  Future<void> saveRecipesFromCloud(List<Recipe> recipes) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final recipe in recipes) {
      batch.insert(
        'recipes',
        _recipeToMap(recipe, synced: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Limpia todas las recetas
  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('recipes');
  }

  /// Cuenta el total de recetas del usuario
  Future<int> countRecipesByUser(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM recipes WHERE userId = ? AND deleted = 0',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

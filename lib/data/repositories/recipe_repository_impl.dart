import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe_firebase_datasource.dart';
import '../datasources/local/recipe_local_datasource.dart';
import '../services/connectivity_service.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeFirebaseDatasource _remoteDatasource;
  final RecipeLocalDatasource _localDatasource;
  final ConnectivityService _connectivityService;

  RecipeRepositoryImpl(
    this._remoteDatasource,
    this._localDatasource,
    this._connectivityService,
  );

  @override
  Future<Recipe> createRecipe(Recipe recipe) async {
    // Siempre guardar primero en local
    await _localDatasource.saveRecipe(recipe, synced: false);

    // Si hay conexión, intentar subir a la nube
    if (_connectivityService.isConnected) {
      try {
        final createdRecipe = await _remoteDatasource.createRecipe(recipe);
        // Actualizar local con el ID de la nube si es diferente
        await _localDatasource.saveRecipe(createdRecipe, synced: true);
        return createdRecipe;
      } catch (e) {
        // Retornar la receta local
        return recipe;
      }
    }

    // Sin conexión, retornar la receta local
    return recipe;
  }

  @override
  Future<List<Recipe>> getRecipesByUser(String userId) async {
    // Intentar obtener de la nube si hay conexión
    if (_connectivityService.isConnected) {
      try {
        final cloudRecipes = await _remoteDatasource.getRecipesByUser(userId);
        // Actualizar cache local
        await _localDatasource.saveRecipesFromCloud(cloudRecipes);
        return cloudRecipes;
      } catch (e) {
        // Error en la nube, usar datos locales como fallback
      }
    }

    // Sin conexión o error, usar datos locales
    return await _localDatasource.getRecipesByUser(userId);
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
    // Intentar obtener de la nube si hay conexión
    if (_connectivityService.isConnected) {
      try {
        final cloudRecipes = await _remoteDatasource.getAllRecipes();
        // Actualizar cache local
        await _localDatasource.saveRecipesFromCloud(cloudRecipes);
        return cloudRecipes;
      } catch (e) {
        // Error en la nube, usar datos locales como fallback
      }
    }

    // Sin conexión o error, usar datos locales
    return await _localDatasource.getAllRecipes();
  }

  @override
  Future<Recipe> getRecipeById(String id) async {
    // Intentar obtener de la nube si hay conexión
    if (_connectivityService.isConnected) {
      try {
        final recipe = await _remoteDatasource.getRecipeById(id);
        // Actualizar cache local
        await _localDatasource.saveRecipe(recipe, synced: true);
        return recipe;
      } catch (e) {
        // Error en la nube, usar datos locales como fallback
      }
    }

    // Sin conexión o error, usar datos locales
    final recipe = await _localDatasource.getRecipeById(id);
    if (recipe == null) {
      throw Exception('Receta no encontrada');
    }
    return recipe;
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    // Siempre actualizar primero en local
    await _localDatasource.updateRecipe(recipe);

    // Si hay conexión, intentar actualizar en la nube
    if (_connectivityService.isConnected) {
      try {
        await _remoteDatasource.updateRecipe(recipe);
        // Marcar como sincronizado
        await _localDatasource.markAsSynced(recipe.id);
      } catch (e) {
        throw Exception('⚠️ Error al actualizar en nube, cambios guardados localmente: $e');
      }
    }
  }

  @override
  Future<void> deleteRecipe(String id) async {
    // Siempre eliminar primero en local (soft delete)
    await _localDatasource.deleteRecipe(id);

    // Si hay conexión, intentar eliminar en la nube
    if (_connectivityService.isConnected) {
      try {
        await _remoteDatasource.deleteRecipe(id);
        // Eliminar permanentemente del local
        await _localDatasource.hardDeleteRecipe(id);
      } catch (e) {
        throw Exception('⚠️ Error al eliminar en nube, marcado para sincronización: $e');
      }
    }
  }
}

import '../../domain/entities/recipe.dart';

abstract class RecipeRepository {
  Future<Recipe> createRecipe(Recipe recipe);
  Future<List<Recipe>> getRecipesByUser(String userId);
  Future<List<Recipe>> getAllRecipes();
  Future<Recipe> getRecipeById(String id);
  Future<void> updateRecipe(Recipe recipe);
  Future<void> deleteRecipe(String id);
}

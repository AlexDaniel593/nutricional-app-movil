import '../../domain/entities/recipe.dart';
import '../repositories/recipe_repository.dart';

class GetRecipesUseCase {
  final RecipeRepository _repository;

  GetRecipesUseCase(this._repository);

  Future<List<Recipe>> callByUser(String userId) {
    return _repository.getRecipesByUser(userId);
  }

  Future<List<Recipe>> callAll() {
    return _repository.getAllRecipes();
  }
}

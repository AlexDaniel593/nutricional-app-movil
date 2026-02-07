import '../../domain/entities/recipe.dart';
import '../repositories/recipe_repository.dart';

class CreateRecipeUseCase {
  final RecipeRepository _repository;

  CreateRecipeUseCase(this._repository);

  Future<Recipe> call(Recipe recipe) {
    return _repository.createRecipe(recipe);
  }
}

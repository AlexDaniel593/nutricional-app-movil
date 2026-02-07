import '../../domain/entities/recipe.dart';
import '../repositories/recipe_repository.dart';

class UpdateRecipeUseCase {
  final RecipeRepository _repository;

  UpdateRecipeUseCase(this._repository);

  Future<void> call(Recipe recipe) {
    return _repository.updateRecipe(recipe);
  }
}

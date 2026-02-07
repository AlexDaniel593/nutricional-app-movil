import '../repositories/recipe_repository.dart';

class DeleteRecipeUseCase {
  final RecipeRepository _repository;

  DeleteRecipeUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.deleteRecipe(id);
  }
}

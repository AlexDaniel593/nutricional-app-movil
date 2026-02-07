class Recipe {
  String id;
  String title;
  String description;
  String imageUrl;
  List<String> ingredients;
  List<String> steps;
  String userId;
  DateTime createdAt;
  int preparationTime;
  int servings;
  String category;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.userId,
    required this.createdAt,
    this.preparationTime = 0,
    this.servings = 1,
    this.category = '',
  });
}

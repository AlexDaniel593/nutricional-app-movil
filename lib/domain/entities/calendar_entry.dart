class CalendarEntry {
  String id;
  String userId;
  String recipeId;
  String recipeTitle;
  String recipeImageUrl;
  DateTime scheduledDate;
  String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  bool notificationSent;
  DateTime createdAt;

  CalendarEntry({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.recipeTitle,
    required this.recipeImageUrl,
    required this.scheduledDate,
    required this.mealType,
    this.notificationSent = false,
    required this.createdAt,
  });
}

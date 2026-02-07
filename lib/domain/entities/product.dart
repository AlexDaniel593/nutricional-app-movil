import 'nutritional_info.dart';

class Product {
  String id;
  String barcode;
  String name;
  String brand;
  String imageUrl;
  String category;
  NutritionalInfo nutritionalInfo;
  String userId;
  DateTime createdAt;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.category,
    required this.nutritionalInfo,
    required this.userId,
    required this.createdAt,
  });
}

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../../domain/entities/product.dart';
import '../../domain/entities/nutritional_info.dart';

/// Servicio para consultar la API de Open Food Facts
class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// Busca un producto por código de barras
  /// Retorna null si no se encuentra
  Future<Product?> getProductByBarcode(String barcode, String userId) async {
    try {
      final url = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        dev.log('Error API: ${response.statusCode}', name: 'OpenFoodFactsService');
        return null;
      }

      final data = jsonDecode(response.body);
      
      // Verificar que el producto existe
      if (data['status'] != 1) {
        dev.log('Producto no encontrado en Open Food Facts', name: 'OpenFoodFactsService');
        return null;
      }

      final productData = data['product'];
      
      // Extraer información nutricional (por 100g)
      final nutriments = productData['nutriments'] ?? {};
      final nutritionalInfo = NutritionalInfo(
        calories: _parseDouble(nutriments['energy-kcal_100g']),
        protein: _parseDouble(nutriments['proteins_100g']),
        carbohydrates: _parseDouble(nutriments['carbohydrates_100g']),
        fat: _parseDouble(nutriments['fat_100g']),
        fiber: _parseDouble(nutriments['fiber_100g']),
        sugar: _parseDouble(nutriments['sugars_100g']),
        sodium: _parseDouble(nutriments['sodium_100g']),
        servingSize: productData['serving_size'] ?? '100g',
      );

      // Crear producto
      final product = Product(
        id: '', // Se asignará al guardar
        barcode: barcode,
        name: productData['product_name'] ?? 'Producto sin nombre',
        brand: productData['brands'] ?? 'Marca desconocida',
        imageUrl: productData['image_url'] ?? '',
        category: productData['categories'] ?? '',
        nutritionalInfo: nutritionalInfo,
        userId: userId,
        createdAt: DateTime.now(),
      );

      return product;
    } catch (e) {
      dev.log('Error consultando Open Food Facts: $e', name: 'OpenFoodFactsService');
      return null;
    }
  }

  /// Convierte un valor dinámico a double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

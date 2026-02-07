import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/nutritional_info.dart';

class ProductFirebaseDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  /// Crear producto
  Future<Product> createProduct(Product product) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'barcode': product.barcode,
        'name': product.name,
        'brand': product.brand,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'nutritionalInfo': product.nutritionalInfo.toJson(),
        'userId': product.userId,
        'createdAt': Timestamp.fromDate(product.createdAt),
      });

      return Product(
        id: docRef.id,
        barcode: product.barcode,
        name: product.name,
        brand: product.brand,
        imageUrl: product.imageUrl,
        category: product.category,
        nutritionalInfo: product.nutritionalInfo,
        userId: product.userId,
        createdAt: product.createdAt,
      );
    } catch (e) {
      throw Exception('Error al crear producto: ${e.toString()}');
    }
  }

  /// Obtener productos por usuario
  Future<List<Product>> getProductsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          barcode: data['barcode'] ?? '',
          name: data['name'] ?? '',
          brand: data['brand'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? '',
          nutritionalInfo: NutritionalInfo.fromJson(Map<String, dynamic>.from(data['nutritionalInfo'] ?? {})),
          userId: data['userId'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    } catch (e) {
      throw Exception('Error al obtener productos: ${e.toString()}');
    }
  }

  /// Obtener producto por ID
  Future<Product> getProductById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) throw Exception('Producto no encontrado');

      final data = doc.data()!;
      return Product(
        id: doc.id,
        barcode: data['barcode'] ?? '',
        name: data['name'] ?? '',
        brand: data['brand'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        category: data['category'] ?? '',
        nutritionalInfo: NutritionalInfo.fromJson(Map<String, dynamic>.from(data['nutritionalInfo'] ?? {})),
        userId: data['userId'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      throw Exception('Error al obtener producto: ${e.toString()}');
    }
  }

  /// Actualizar producto
  Future<void> updateProduct(Product product) async {
    try {
      await _firestore.collection(_collection).doc(product.id).update({
        'name': product.name,
        'brand': product.brand,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'nutritionalInfo': product.nutritionalInfo.toJson(),
      });
    } catch (e) {
      throw Exception('Error al actualizar producto: ${e.toString()}');
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar producto: ${e.toString()}');
    }
  }
}

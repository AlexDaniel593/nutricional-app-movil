import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/nutritional_info.dart';
import 'database_helper.dart';

/// Datasource local para productos usando SQLite
class ProductLocalDatasource {
  final DatabaseHelper _dbHelper;

  ProductLocalDatasource(this._dbHelper);

  /// Convierte un producto a Map para SQLite
  Map<String, dynamic> _productToMap(Product product, {bool synced = false}) {
    return {
      'id': product.id,
      'barcode': product.barcode,
      'name': product.name,
      'brand': product.brand,
      'imageUrl': product.imageUrl,
      'category': product.category,
      'nutritionalInfo': jsonEncode(product.nutritionalInfo.toJson()),
      'userId': product.userId,
      'createdAt': product.createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
      'deleted': 0,
    };
  }

  /// Convierte un Map de SQLite a Product
  Product _mapToProduct(Map<String, dynamic> data) {
    return Product(
      id: data['id'] as String,
      barcode: data['barcode'] as String,
      name: data['name'] as String,
      brand: data['brand'] as String,
      imageUrl: data['imageUrl'] as String,
      category: data['category'] as String,
      nutritionalInfo: NutritionalInfo.fromJson(jsonDecode(data['nutritionalInfo'] as String)),
      userId: data['userId'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  /// Inserta o actualiza un producto
  Future<void> saveProduct(Product product, {bool synced = false}) async {
    final db = await _dbHelper.database;
    await db.insert(
      'products',
      _productToMap(product, synced: synced),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene un producto por ID
  Future<Product?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'products',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _mapToProduct(results.first);
  }

  /// Obtiene un producto por código de barras
  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'products',
      where: 'barcode = ? AND deleted = 0',
      whereArgs: [barcode],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _mapToProduct(results.first);
  }

  /// Obtiene todos los productos de un usuario
  Future<List<Product>> getProductsByUser(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'products',
      where: 'userId = ? AND deleted = 0',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return results.map(_mapToProduct).toList();
  }

  /// Obtiene todos los productos
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'products',
      where: 'deleted = 0',
      orderBy: 'createdAt DESC',
    );

    return results.map(_mapToProduct).toList();
  }

  /// Actualiza un producto
  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {
        'name': product.name,
        'brand': product.brand,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'nutritionalInfo': jsonEncode(product.nutritionalInfo.toJson()),
        'updatedAt': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Elimina un producto (soft delete)
  Future<void> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {
        'deleted': 1,
        'synced': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un producto permanentemente
  Future<void> hardDeleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene productos no sincronizados
  Future<List<Product>> getUnsyncedProducts() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'products',
      where: 'synced = 0 AND deleted = 0',
      orderBy: 'createdAt ASC',
    );

    return results.map(_mapToProduct).toList();
  }

  /// Marca un producto como sincronizado
  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {'synced': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Guarda múltiples productos desde la nube
  Future<void> saveProductsFromCloud(List<Product> products) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final product in products) {
      batch.insert(
        'products',
        _productToMap(product, synced: true),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Obtiene productos eliminados
  Future<List<String>> getDeletedProductIds() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'products',
      columns: ['id'],
      where: 'deleted = 1',
    );

    return results.map((r) => r['id'] as String).toList();
  }
}

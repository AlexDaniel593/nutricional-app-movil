import 'dart:developer' as dev;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local_datasource.dart';
import '../datasources/product_firebase_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDatasource _localDatasource;
  final ProductFirebaseDatasource _firebaseDatasource;

  ProductRepositoryImpl(this._localDatasource, this._firebaseDatasource);

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Future<Product> createProduct(Product product) async {
    // Guardar localmente primero
    await _localDatasource.saveProduct(product, synced: false);

    // Intentar sincronizar con Firebase
    if (await _isOnline()) {
      try {
        final cloudProduct = await _firebaseDatasource.createProduct(product);
        // Actualizar con el ID de Firebase
        final updatedProduct = Product(
          id: cloudProduct.id,
          barcode: product.barcode,
          name: product.name,
          brand: product.brand,
          imageUrl: product.imageUrl,
          category: product.category,
          nutritionalInfo: product.nutritionalInfo,
          userId: product.userId,
          createdAt: product.createdAt,
        );
        await _localDatasource.saveProduct(updatedProduct, synced: true);
        return updatedProduct;
      } catch (e) {
        return product;
      }
    }

    return product;
  }

  @override
  Future<List<Product>> getProductsByUser(String userId) async {
    if (await _isOnline()) {
      try {
        final cloudProducts = await _firebaseDatasource.getProductsByUser(userId);
        await _localDatasource.saveProductsFromCloud(cloudProducts);
        return cloudProducts;
      } catch (e) {
        return await _localDatasource.getProductsByUser(userId);
      }
    }

    return await _localDatasource.getProductsByUser(userId);
  }

  @override
  Future<Product?> getProductById(String id) async {
    // Intentar obtener de la nube primero
    if (await _isOnline()) {
      try {
        final cloudProduct = await _firebaseDatasource.getProductById(id);
        await _localDatasource.saveProduct(cloudProduct, synced: true);
        return cloudProduct;
      } catch (e) {
        dev.log('Error obteniendo producto de Firebase: $e', name: 'ProductRepository');
      }
    }

    // Fallback a local
    return await _localDatasource.getProductById(id);
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    return await _localDatasource.getProductByBarcode(barcode);
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _localDatasource.updateProduct(product);

    if (await _isOnline()) {
      try {
        await _firebaseDatasource.updateProduct(product);
        await _localDatasource.markAsSynced(product.id);
      } catch (e) {
        dev.log('Error actualizando en Firebase: $e', name: 'ProductRepository');
      }
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _localDatasource.deleteProduct(id);

    if (await _isOnline()) {
      try {
        await _firebaseDatasource.deleteProduct(id);
        await _localDatasource.hardDeleteProduct(id);
      } catch (e) {
        dev.log('Error eliminando en Firebase: $e', name: 'ProductRepository');
      }
    }
  }

  /// Sincronizar cambios pendientes con Firebase
  Future<void> syncPendingChanges() async {
    if (!(await _isOnline())) return;

    try {
      // Sincronizar productos nuevos/actualizados
      final unsyncedProducts = await _localDatasource.getUnsyncedProducts();
      for (final product in unsyncedProducts) {
        try {
          await _firebaseDatasource.updateProduct(product);
          await _localDatasource.markAsSynced(product.id);
        } catch (e) {
          dev.log('Error sincronizando producto ${product.id}: $e', name: 'ProductRepository');
        }
      }

      // Sincronizar productos eliminados
      final deletedIds = await _localDatasource.getDeletedProductIds();
      for (final id in deletedIds) {
        try {
          await _firebaseDatasource.deleteProduct(id);
          await _localDatasource.hardDeleteProduct(id);
        } catch (e) {
          dev.log('Error eliminando producto $id: $e', name: 'ProductRepository');
        }
      }
    } catch (e) {
      dev.log('Error en sincronización: $e', name: 'ProductRepository');
    }
  }
}

import '../entities/product.dart';

abstract class ProductRepository {
  Future<Product> createProduct(Product product);
  Future<List<Product>> getProductsByUser(String userId);
  Future<Product?> getProductById(String id);
  Future<Product?> getProductByBarcode(String barcode);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
}

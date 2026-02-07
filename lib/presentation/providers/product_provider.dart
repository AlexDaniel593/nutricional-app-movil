import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/nutritional_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/create_product.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/update_product.dart';
import '../../domain/usecases/delete_product.dart';
import '../../data/services/open_food_facts_service.dart';

class ProductProvider with ChangeNotifier {
  final CreateProduct _createProduct;
  final GetProducts _getProducts;
  final UpdateProduct _updateProduct;
  final DeleteProduct _deleteProduct;
  final OpenFoodFactsService _openFoodFactsService;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  Product? _scannedProduct;

  ProductProvider({
    required CreateProduct createProduct,
    required GetProducts getProducts,
    required UpdateProduct updateProduct,
    required DeleteProduct deleteProduct,
    required OpenFoodFactsService openFoodFactsService,
  })  : _createProduct = createProduct,
        _getProducts = getProducts,
        _updateProduct = updateProduct,
        _deleteProduct = deleteProduct,
        _openFoodFactsService = openFoodFactsService;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Product? get scannedProduct => _scannedProduct;

  /// Verifica si el producto ya está guardado
  bool isProductAlreadySaved(String barcode) {
    return _products.any((p) => p.barcode == barcode);
  }

  /// Carga productos del usuario
  Future<void> loadProducts(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _getProducts(userId);
    } catch (e) {
      _error = e.toString();
      dev.log('Error cargando productos: $e', name: 'ProductProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Escanea un código de barras y consulta Open Food Facts
  Future<Product?> scanBarcode(String barcode, String userId) async {
    _isLoading = true;
    _error = null;
    _scannedProduct = null;
    notifyListeners();

    try {
      // Verificar si ya existe localmente
      final existing = _products.firstWhere(
        (p) => p.barcode == barcode,
        orElse: () => Product(
          id: '',
          barcode: '',
          name: '',
          brand: '',
          imageUrl: '',
          category: '',
          nutritionalInfo: _defaultNutritionalInfo(),
          userId: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existing.id.isNotEmpty) {
        _scannedProduct = existing;
        return existing;
      }

      // Consultar Open Food Facts
      final product = await _openFoodFactsService.getProductByBarcode(barcode, userId);
      
      if (product != null) {
        _scannedProduct = product;
      } else {
        _error = 'Producto no encontrado en Open Food Facts';
      }

      return product;
    } catch (e) {
      _error = e.toString();
      dev.log('Error escaneando producto: $e', name: 'ProductProvider');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo producto
  Future<void> createProductFromScanned(String userId) async {
    if (_scannedProduct == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final productToCreate = Product(
        id: const Uuid().v4(),
        barcode: _scannedProduct!.barcode,
        name: _scannedProduct!.name,
        brand: _scannedProduct!.brand,
        imageUrl: _scannedProduct!.imageUrl,
        category: _scannedProduct!.category,
        nutritionalInfo: _scannedProduct!.nutritionalInfo,
        userId: userId,
        createdAt: DateTime.now(),
      );

      final created = await _createProduct(productToCreate);
      _products.insert(0, created);
      _scannedProduct = null;
    } catch (e) {
      _error = e.toString();
      dev.log('Error creando producto: $e', name: 'ProductProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea un producto manual
  Future<void> createProduct(Product product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _createProduct(product);
      _products.insert(0, created);
    } catch (e) {
      _error = e.toString();
      dev.log('Error creando producto: $e', name: 'ProductProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza un producto
  Future<void> updateProduct(Product product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
    } catch (e) {
      _error = e.toString();
      dev.log('Error actualizando producto: $e', name: 'ProductProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina un producto
  Future<void> deleteProduct(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
    } catch (e) {
      _error = e.toString();
      dev.log('Error eliminando producto: $e', name: 'ProductProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el producto escaneado
  void clearScannedProduct() {
    _scannedProduct = null;
    notifyListeners();
  }

  /// Limpia el error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// NutritionalInfo por defecto
  _defaultNutritionalInfo() {
    return NutritionalInfo(
      calories: 0,
      protein: 0,
      carbohydrates: 0,
      fat: 0,
      fiber: 0,
      sugar: 0,
      sodium: 0,
      servingSize: '100g',
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/create_recipe.dart';
import '../../domain/usecases/get_recipes.dart';
import '../../domain/usecases/update_recipe.dart';
import '../../domain/usecases/delete_recipe.dart';
import '../../data/datasources/recipe_firebase_datasource.dart';
import '../../data/datasources/cloudinary_datasource.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/recipe_local_datasource.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/sync_service.dart';

class RecipeProvider with ChangeNotifier {
  List<Recipe> _recipes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = true;
  int _pendingSyncCount = 0;

  late final CreateRecipeUseCase _createRecipe;
  late final GetRecipesUseCase _getRecipes;
  late final UpdateRecipeUseCase _updateRecipe;
  late final DeleteRecipeUseCase _deleteRecipe;
  late final CloudinaryDatasource _cloudinaryDatasource;
  late final SyncService _syncService;
  late final ConnectivityService _connectivityService;

  List<Recipe> get recipes => _recipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncCount;

  RecipeProvider() {
    // Inicializar servicios
    _connectivityService = ConnectivityService.instance;
    final dbHelper = DatabaseHelper.instance;
    final localDatasource = RecipeLocalDatasource(dbHelper);
    final remoteDatasource = RecipeFirebaseDatasource();
    
    final repository = RecipeRepositoryImpl(
      remoteDatasource,
      localDatasource,
      _connectivityService,
    );
    
    _cloudinaryDatasource = CloudinaryDatasource();
    _syncService = SyncService(
      localDatasource,
      remoteDatasource,
      _connectivityService,
    );
    
    _createRecipe = CreateRecipeUseCase(repository);
    _getRecipes = GetRecipesUseCase(repository);
    _updateRecipe = UpdateRecipeUseCase(repository);
    _deleteRecipe = DeleteRecipeUseCase(repository);

    // Inicializar conectividad y sincronización
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _connectivityService.initialize();
    _isOnline = _connectivityService.isConnected;
    
    // Escuchar cambios de conectividad
    _connectivityService.connectionStream.listen((isConnected) {
      _isOnline = isConnected;
      notifyListeners();
    });

    // Iniciar sincronización automática
    _syncService.startAutoSync();

    // Actualizar contador de pendientes
    _updatePendingSyncCount();
  }

  Future<void> _updatePendingSyncCount() async {
    _pendingSyncCount = await _syncService.getPendingSyncCount();
    notifyListeners();
  }

  Future<void> loadRecipes({String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (userId != null) {
        _recipes = await _getRecipes.callByUser(userId);
      } else {
        _recipes = await _getRecipes.callAll();
      }
      await _updatePendingSyncCount();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecipe({
    required String title,
    required String description,
    required File imageFile,
    required List<String> ingredients,
    required List<String> steps,
    required String userId,
    int preparationTime = 0,
    int servings = 1,
    String category = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String imageUrl;
      
      // Si hay conexión, subir imagen a Cloudinary
      if (_isOnline) {
        try {
          imageUrl = await _cloudinaryDatasource.uploadImage(imageFile);
        } catch (e) {
          // Si falla la subida, usar ruta local
          imageUrl = imageFile.path;
        }
      } else {
        // Sin conexión, usar ruta local del archivo
        imageUrl = imageFile.path;
      }

      // Crear receta
      final recipe = Recipe(
        id: '',
        title: title,
        description: description,
        imageUrl: imageUrl,
        ingredients: ingredients,
        steps: steps,
        userId: userId,
        createdAt: DateTime.now(),
        preparationTime: preparationTime,
        servings: servings,
        category: category,
      );

      final newRecipe = await _createRecipe(recipe);
      _recipes.insert(0, newRecipe);
      await _updatePendingSyncCount();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> modifyRecipe({
    required String id,
    required String title,
    required String description,
    File? imageFile,
    String? currentImageUrl,
    required List<String> ingredients,
    required List<String> steps,
    required String userId,
    required DateTime createdAt,
    int preparationTime = 0,
    int servings = 1,
    String category = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String imageUrl = currentImageUrl ?? '';
      
      // Si hay nueva imagen
      if (imageFile != null) {
        // Si hay conexión, subir a Cloudinary
        if (_isOnline) {
          try {
            imageUrl = await _cloudinaryDatasource.uploadImage(imageFile);
          } catch (e) {
            // Si falla la subida, usar ruta local
            imageUrl = imageFile.path;
          }
        } else {
          // Sin conexión, usar ruta local
          imageUrl = imageFile.path;
        }
      }

      final recipe = Recipe(
        id: id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        ingredients: ingredients,
        steps: steps,
        userId: userId,
        createdAt: createdAt,
        preparationTime: preparationTime,
        servings: servings,
        category: category,
      );

      await _updateRecipe(recipe);
      
      final index = _recipes.indexWhere((r) => r.id == id);
      if (index != -1) {
        _recipes[index] = recipe;
      }
      await _updatePendingSyncCount();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeRecipe(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteRecipe(id);
      _recipes.removeWhere((recipe) => recipe.id == id);
      await _updatePendingSyncCount();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fuerza una sincronización manual
  Future<void> syncNow() async {
    try {
      await _syncService.forceSyncNow();
      await _updatePendingSyncCount();
      // Recargar recetas después de sincronizar
      await loadRecipes();
    } catch (e) {
      _errorMessage = 'Error al sincronizar: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncService.stopAutoSync();
    super.dispose();
  }
}

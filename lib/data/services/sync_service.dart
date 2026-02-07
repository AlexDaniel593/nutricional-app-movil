import 'dart:async';
import 'dart:developer' as dev;
import '../datasources/local/recipe_local_datasource.dart';
import '../datasources/recipe_firebase_datasource.dart';
import 'connectivity_service.dart';

/// Servicio para sincronizar datos entre local y la nube
class SyncService {
  final RecipeLocalDatasource _localDatasource;
  final RecipeFirebaseDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;
  Timer? _periodicSyncTimer;

  SyncService(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  /// Inicia el servicio de sincronización automática
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    // Escuchar cambios de conectividad
    _connectivityService.connectionStream.listen((isConnected) {
      if (isConnected) {
        dev.log('🔄 Conexión restaurada, iniciando sincronización...', name: 'SyncService');
        syncAll();
      }
    });

    // Sincronización periódica
    _periodicSyncTimer = Timer.periodic(interval, (_) {
      if (_connectivityService.isConnected) {
        syncAll();
      }
    });

    // Sincronización inicial si hay conexión
    if (_connectivityService.isConnected) {
      Future.delayed(const Duration(seconds: 2), () => syncAll());
    }
  }

  /// Detiene la sincronización automática
  void stopAutoSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Sincroniza todos los datos
  Future<void> syncAll() async {
    if (_isSyncing) {
      dev.log('⏳ Ya hay una sincronización en curso...', name: 'SyncService');
      return;
    }

    if (!_connectivityService.isConnected) {
      dev.log('📴 Sin conexión, sincronización pospuesta', name: 'SyncService');
      return;
    }

    _isSyncing = true;
    dev.log('🔄 Iniciando sincronización completa...', name: 'SyncService');

    try {
      await syncRecipes();
      dev.log('✅ Sincronización completada exitosamente', name: 'SyncService');
    } catch (e) {
      dev.log('❌ Error en sincronización: $e', name: 'SyncService');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sincroniza recetas (subir cambios locales y bajar cambios remotos)
  Future<void> syncRecipes() async {
    try {
      // 1. Subir recetas no sincronizadas
      await _uploadUnsyncedRecipes();

      // 2. Eliminar recetas marcadas como eliminadas
      await _deleteRemovedRecipes();

      dev.log('✅ Recetas sincronizadas', name: 'SyncService');
    } catch (e) {
      dev.log('❌ Error al sincronizar recetas: $e', name: 'SyncService');
      rethrow;
    }
  }

  /// Sube recetas locales no sincronizadas a la nube
  Future<void> _uploadUnsyncedRecipes() async {
    try {
      final unsyncedRecipes = await _localDatasource.getUnsyncedRecipes();
      
      if (unsyncedRecipes.isEmpty) {
        dev.log('📭 No hay recetas pendientes de subir', name: 'SyncService');
        return;
      }

      dev.log('📤 Subiendo ${unsyncedRecipes.length} receta(s)...', name: 'SyncService');

      for (final recipe in unsyncedRecipes) {
        try {
          // Verificar si existe en la nube
          final existsInCloud = await _checkRecipeExistsInCloud(recipe.id);

          if (existsInCloud) {
            // Actualizar en la nube
            await _remoteDatasource.updateRecipe(recipe);
            dev.log('  ✓ Actualizada: ${recipe.title}', name: 'SyncService');
          } else {
            // Crear en la nube
            await _remoteDatasource.createRecipe(recipe);
            dev.log('  ✓ Creada: ${recipe.title}', name: 'SyncService');
          }

          // Marcar como sincronizada localmente
          await _localDatasource.markAsSynced(recipe.id);
        } catch (e) {
          dev.log('  ✗ Error al subir "${recipe.title}": $e', name: 'SyncService');
          // Continuar con la siguiente receta
        }
      }
    } catch (e) {
      dev.log('❌ Error al subir recetas: $e', name: 'SyncService');
      rethrow;
    }
  }

  /// Elimina en la nube las recetas marcadas como eliminadas localmente
  Future<void> _deleteRemovedRecipes() async {
    try {
      final deletedIds = await _localDatasource.getDeletedUnsyncedRecipeIds();
      
      if (deletedIds.isEmpty) {
        dev.log('📭 No hay recetas pendientes de eliminar', name: 'SyncService');
        return;
      }

      dev.log('🗑️  Eliminando ${deletedIds.length} receta(s)...', name: 'SyncService');

      for (final id in deletedIds) {
        try {
          await _remoteDatasource.deleteRecipe(id);
          await _localDatasource.hardDeleteRecipe(id);
          dev.log('  ✓ Eliminada: $id', name: 'SyncService');
        } catch (e) {
          dev.log('  ✗ Error al eliminar "$id": $e', name: 'SyncService');
        }
      }
    } catch (e) {
      dev.log('❌ Error al eliminar recetas: $e', name: 'SyncService');
      rethrow;
    }
  }

  /// Descarga recetas de la nube para un usuario
  Future<void> downloadRecipesForUser(String userId) async {
    if (!_connectivityService.isConnected) {
      dev.log('📴 Sin conexión, usando datos locales', name: 'SyncService');
      return;
    }

    try {
      dev.log('📥 Descargando recetas del usuario...', name: 'SyncService');
      final cloudRecipes = await _remoteDatasource.getRecipesByUser(userId);
      
      // Guardar en local
      await _localDatasource.saveRecipesFromCloud(cloudRecipes);
      
      dev.log('✅ ${cloudRecipes.length} receta(s) descargadas', name: 'SyncService');
    } catch (e) {
      dev.log('❌ Error al descargar recetas: $e', name: 'SyncService');
      // No lanzar error, permitir trabajar offline
    }
  }

  /// Verifica si una receta existe en la nube
  Future<bool> _checkRecipeExistsInCloud(String id) async {
    try {
      await _remoteDatasource.getRecipeById(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fuerza una sincronización inmediata
  Future<void> forceSyncNow() async {
    if (!_connectivityService.isConnected) {
      throw Exception('No hay conexión a internet');
    }
    await syncAll();
  }

  /// Verifica el estado de la sincronización
  bool get isSyncing => _isSyncing;

  /// Obtiene el número de elementos pendientes de sincronizar
  Future<int> getPendingSyncCount() async {
    final unsyncedRecipes = await _localDatasource.getUnsyncedRecipes();
    final deletedRecipes = await _localDatasource.getDeletedUnsyncedRecipeIds();
    return unsyncedRecipes.length + deletedRecipes.length;
  }
}

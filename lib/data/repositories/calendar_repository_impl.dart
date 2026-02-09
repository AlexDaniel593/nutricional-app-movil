import '../../domain/entities/calendar_entry.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_firebase_datasource.dart';
import '../datasources/local/calendar_local_datasource.dart';
import '../services/connectivity_service.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarFirebaseDatasource _remoteDatasource;
  final CalendarLocalDatasource _localDatasource;
  final ConnectivityService _connectivityService;

  CalendarRepositoryImpl(
    this._remoteDatasource,
    this._localDatasource,
    this._connectivityService,
  );

  @override
  Future<CalendarEntry> createEntry(CalendarEntry entry) async {
    // Siempre guardar primero en local
    await _localDatasource.saveEntry(entry, synced: false);

    // Si hay conexión, intentar subir a la nube
    if (_connectivityService.isConnected) {
      try {
        final createdEntry = await _remoteDatasource.createEntry(entry);
        // Actualizar local con el ID de la nube si es diferente
        await _localDatasource.saveEntry(createdEntry, synced: true);
        return createdEntry;
      } catch (e) {
        // Retornar la entrada local
        return entry;
      }
    }

    // Sin conexión, retornar la entrada local
    return entry;
  }

  @override
  Future<List<CalendarEntry>> getEntriesByUser(String userId) async {
    // Intentar obtener de la nube si hay conexión
    if (_connectivityService.isConnected) {
      try {
        final cloudEntries = await _remoteDatasource.getEntriesByUser(userId);
        // Actualizar cache local
        await _localDatasource.saveEntriesFromCloud(cloudEntries);
        return cloudEntries;
      } catch (e) {
        // Error en la nube, usar datos locales como fallback
      }
    }

    // Sin conexión o error, usar datos locales
    return await _localDatasource.getEntriesByUser(userId);
  }

  @override
  Future<List<CalendarEntry>> getEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Primero intentar obtener de local (es más rápido)
    final localEntries = await _localDatasource.getEntriesByDateRange(userId, startDate, endDate);
    
    // Si hay conexión, sincronizar en segundo plano sin bloquear
    if (_connectivityService.isConnected) {
      // No await - sincronizar en background con un pequeño delay
      Future.delayed(const Duration(milliseconds: 1000)).then((_) async {
        try {
          final cloudEntries = await _remoteDatasource.getEntriesByDateRange(
            userId,
            startDate,
            endDate,
          );
          // Actualizar cache local con los datos de la nube
          await _localDatasource.saveEntriesFromCloud(cloudEntries);
        } catch (_) {
          // Ignorar errores de sincronización background
        }
      });
    }

    return localEntries;
  }

  @override
  Future<CalendarEntry> getEntryById(String id) async {
    // Intentar obtener de la nube si hay conexión
    if (_connectivityService.isConnected) {
      try {
        final entry = await _remoteDatasource.getEntryById(id);
        // Actualizar cache local
        await _localDatasource.saveEntry(entry, synced: true);
        return entry;
      } catch (e) {
        // Error en la nube, usar datos locales como fallback
      }
    }

    // Sin conexión o error, usar datos locales
    final entry = await _localDatasource.getEntryById(id);
    if (entry == null) {
      throw Exception('Entrada no encontrada');
    }
    return entry;
  }

  @override
  Future<void> updateEntry(CalendarEntry entry) async {
    // Siempre actualizar primero en local
    await _localDatasource.updateEntry(entry);

    // Si hay conexión, intentar actualizar en la nube
    if (_connectivityService.isConnected) {
      try {
        await _remoteDatasource.updateEntry(entry);
        // Marcar como sincronizado
        await _localDatasource.markAsSynced(entry.id);
      } catch (e) {
        // Se sincronizará después
      }
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    // Si hay conexión, PRIMERO eliminar de Firebase
    if (_connectivityService.isConnected) {
      try {
        await _remoteDatasource.deleteEntry(id);
      } catch (e) {
        // Si falla Firebase, marcar como eliminada para sincronizar después
        await _localDatasource.deleteEntry(id);
        return;
      }
    } else {
      // Sin conexión, solo marcar como eliminada localmente
      await _localDatasource.deleteEntry(id);
      return;
    }
    
    // Si llegamos aquí, Firebase se eliminó correctamente
    // Ahora eliminar permanentemente de local
    await _localDatasource.hardDeleteEntry(id);
  }

  @override
  Future<void> syncAllFromCloud(String userId) async {
    // Solo sincronizar si hay conexión
    if (!_connectivityService.isConnected) {
      return;
    }

    try {
      // Obtener todas las entradas del usuario desde Firebase
      final cloudEntries = await _remoteDatasource.getEntriesByUser(userId);
      // Guardar todas las entradas en la base de datos local
      await _localDatasource.saveEntriesFromCloud(cloudEntries);
    } catch (e) {
      // Falló la sincronización, se intentará después
    }
  }
}

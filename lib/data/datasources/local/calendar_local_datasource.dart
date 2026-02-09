import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/calendar_entry.dart';
import 'database_helper.dart';

/// Datasource local para entradas de calendario usando SQLite
class CalendarLocalDatasource {
  final DatabaseHelper _dbHelper;

  CalendarLocalDatasource(this._dbHelper);

  /// Convierte una entrada de calendario a Map para SQLite
  Map<String, dynamic> _entryToMap(CalendarEntry entry, {bool synced = false}) {
    return {
      'id': entry.id,
      'userId': entry.userId,
      'recipeId': entry.recipeId,
      'recipeTitle': entry.recipeTitle,
      'recipeImageUrl': entry.recipeImageUrl,
      'scheduledDate': entry.scheduledDate.toIso8601String(),
      'mealType': entry.mealType,
      'notificationSent': entry.notificationSent ? 1 : 0,
      'createdAt': entry.createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
      'deleted': 0,
    };
  }

  /// Convierte un Map de SQLite a CalendarEntry
  CalendarEntry _mapToEntry(Map<String, dynamic> data) {
    return CalendarEntry(
      id: data['id'] as String,
      userId: data['userId'] as String,
      recipeId: data['recipeId'] as String,
      recipeTitle: data['recipeTitle'] as String,
      recipeImageUrl: data['recipeImageUrl'] as String,
      scheduledDate: DateTime.parse(data['scheduledDate'] as String),
      mealType: data['mealType'] as String,
      notificationSent: (data['notificationSent'] as int) == 1,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  /// Inserta o actualiza una entrada
  Future<void> saveEntry(CalendarEntry entry, {bool synced = false}) async {
    final db = await _dbHelper.database;
    await db.insert(
      'calendar_entries',
      _entryToMap(entry, synced: synced),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene una entrada por ID
  Future<CalendarEntry?> getEntryById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'calendar_entries',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _mapToEntry(results.first);
  }

  /// Obtiene todas las entradas de un usuario para una fecha específica
  Future<List<CalendarEntry>> getEntriesByDate(String userId, DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final results = await db.query(
      'calendar_entries',
      where: 'userId = ? AND scheduledDate >= ? AND scheduledDate <= ? AND deleted = 0',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'scheduledDate ASC',
    );

    return results.map(_mapToEntry).toList();
  }

  /// Obtiene entradas de un rango de fechas
  Future<List<CalendarEntry>> getEntriesByDateRange(
    String userId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'calendar_entries',
      where: 'userId = ? AND scheduledDate >= ? AND scheduledDate <= ? AND deleted = 0',
      whereArgs: [userId, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'scheduledDate ASC',
    );

    return results.map(_mapToEntry).toList();
  }

  /// Obtiene todas las entradas de un usuario
  Future<List<CalendarEntry>> getEntriesByUser(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'calendar_entries',
      where: 'userId = ? AND deleted = 0',
      whereArgs: [userId],
      orderBy: 'scheduledDate DESC',
    );

    return results.map(_mapToEntry).toList();
  }

  /// Actualiza una entrada
  Future<void> updateEntry(CalendarEntry entry) async {
    final db = await _dbHelper.database;
    await db.update(
      'calendar_entries',
      {
        'recipeId': entry.recipeId,
        'recipeTitle': entry.recipeTitle,
        'recipeImageUrl': entry.recipeImageUrl,
        'scheduledDate': entry.scheduledDate.toIso8601String(),
        'mealType': entry.mealType,
        'notificationSent': entry.notificationSent ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Elimina una entrada (soft delete)
  Future<void> deleteEntry(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'calendar_entries',
      {
        'deleted': 1,
        'synced': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina una entrada permanentemente
  Future<void> hardDeleteEntry(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'calendar_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene entradas no sincronizadas
  Future<List<CalendarEntry>> getUnsyncedEntries() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'calendar_entries',
      where: 'synced = 0 AND deleted = 0',
      orderBy: 'createdAt ASC',
    );

    return results.map(_mapToEntry).toList();
  }

  /// Marca una entrada como sincronizada
  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'calendar_entries',
      {'synced': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Guarda múltiples entradas desde la nube
  Future<void> saveEntriesFromCloud(List<CalendarEntry> entries) async {
    final db = await _dbHelper.database;
    
    // Obtener IDs de entradas marcadas como eliminadas localmente
    final deletedIds = await getDeletedEntryIds();
    final deletedSet = deletedIds.toSet();
    
    final batch = db.batch();

    for (final entry in entries) {
      // No sobrescribir entradas que fueron eliminadas localmente
      if (!deletedSet.contains(entry.id)) {
        batch.insert(
          'calendar_entries',
          _entryToMap(entry, synced: true),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit(noResult: true);
  }

  /// Obtiene entradas eliminadas
  Future<List<String>> getDeletedEntryIds() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'calendar_entries',
      columns: ['id'],
      where: 'deleted = 1',
    );

    return results.map((r) => r['id'] as String).toList();
  }

  /// Marca una entrada como notificación enviada
  Future<void> markNotificationSent(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'calendar_entries',
      {'notificationSent': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene entradas pendientes de notificación
  Future<List<CalendarEntry>> getPendingNotifications(DateTime now) async {
    final db = await _dbHelper.database;
    final oneHourLater = now.add(const Duration(hours: 1, minutes: 5));
    
    final results = await db.query(
      'calendar_entries',
      where: 'notificationSent = 0 AND deleted = 0 AND scheduledDate <= ? AND scheduledDate > ?',
      whereArgs: [oneHourLater.toIso8601String(), now.toIso8601String()],
    );

    return results.map(_mapToEntry).toList();
  }
}

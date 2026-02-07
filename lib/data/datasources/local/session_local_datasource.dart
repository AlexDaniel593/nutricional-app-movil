import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/user.dart';
import 'database_helper.dart';

/// Datasource local para manejar la sesión activa del usuario
class SessionLocalDatasource {
  final DatabaseHelper _dbHelper;

  SessionLocalDatasource(this._dbHelper);

  /// Guarda la sesión activa del usuario
  Future<void> saveActiveSession(User user) async {
    final db = await _dbHelper.database;
    
    // Primero eliminar cualquier sesión anterior
    await db.delete('active_session');
    
    // Insertar nueva sesión
    await db.insert(
      'active_session',
      {
        'id': 1, // Siempre ID 1 para mantener solo una sesión
        'userId': user.id,
        'username': user.username,
        'email': user.email,
        'isActive': 1,
        'loginAt': DateTime.now().toIso8601String(),
        'lastAccessAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene la sesión activa si existe
  Future<User?> getActiveSession() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'active_session',
      where: 'id = ? AND isActive = ?',
      whereArgs: [1, 1],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final data = results.first;
    
    // Actualizar último acceso
    await updateLastAccess();
    
    return User(
      id: data['userId'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
    );
  }

  /// Verifica si hay una sesión activa
  Future<bool> hasActiveSession() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'active_session',
      where: 'id = ? AND isActive = ?',
      whereArgs: [1, 1],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  /// Actualiza el último acceso de la sesión
  Future<void> updateLastAccess() async {
    final db = await _dbHelper.database;
    await db.update(
      'active_session',
      {'lastAccessAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Cierra la sesión activa
  Future<void> closeSession() async {
    final db = await _dbHelper.database;
    await db.delete('active_session');
  }

  /// Marca la sesión como inactiva (sin eliminarla)
  Future<void> deactivateSession() async {
    final db = await _dbHelper.database;
    await db.update(
      'active_session',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Obtiene información de la sesión
  Future<Map<String, dynamic>?> getSessionInfo() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'active_session',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Verifica si la sesión ha expirado (por ejemplo, después de 30 días)
  Future<bool> isSessionExpired({Duration maxAge = const Duration(days: 30)}) async {
    final sessionInfo = await getSessionInfo();
    if (sessionInfo == null) return true;

    final lastAccess = DateTime.parse(sessionInfo['lastAccessAt'] as String);
    final now = DateTime.now();
    final difference = now.difference(lastAccess);

    return difference > maxAge;
  }
}

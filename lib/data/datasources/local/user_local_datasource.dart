import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/user.dart';
import 'database_helper.dart';

/// Datasource local para usuarios usando SQLite
class UserLocalDatasource {
  final DatabaseHelper _dbHelper;

  UserLocalDatasource(this._dbHelper);

  /// Inserta o actualiza un usuario
  Future<void> saveUser(User user) async {
    final db = await _dbHelper.database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'synced': 1,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene un usuario por ID
  Future<User?> getUserById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final data = results.first;
    return User(
      id: data['id'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
    );
  }

  /// Obtiene un usuario por email
  Future<User?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final data = results.first;
    return User(
      id: data['id'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
    );
  }

  /// Obtiene todos los usuarios
  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final results = await db.query('users');

    return results.map((data) => User(
      id: data['id'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
    )).toList();
  }

  /// Elimina un usuario
  Future<void> deleteUser(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza un usuario
  Future<void> updateUser(User user) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {
        'username': user.username,
        'email': user.email,
        'updatedAt': DateTime.now().toIso8601String(),
        'synced': 0, // Marcar como no sincronizado
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Obtiene usuarios no sincronizados
  Future<List<User>> getUnsyncedUsers() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'synced = ?',
      whereArgs: [0],
    );

    return results.map((data) => User(
      id: data['id'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
    )).toList();
  }

  /// Marca un usuario como sincronizado
  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Limpia todos los usuarios
  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('users');
  }
}

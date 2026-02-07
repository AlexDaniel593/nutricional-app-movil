import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper para manejar la base de datos SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'nutricional.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Tabla de sesión activa
    await db.execute('''
      CREATE TABLE active_session(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        userId TEXT NOT NULL,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        loginAt TEXT NOT NULL,
        lastAccessAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Tabla de recetas
    await db.execute('''
      CREATE TABLE recipes(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        steps TEXT NOT NULL,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        preparationTime INTEGER DEFAULT 0,
        servings INTEGER DEFAULT 1,
        category TEXT DEFAULT '',
        synced INTEGER DEFAULT 0,
        updatedAt TEXT NOT NULL,
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Tabla de sincronización pendiente
    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_recipes_userId ON recipes(userId)');
    await db.execute('CREATE INDEX idx_recipes_synced ON recipes(synced)');
    await db.execute('CREATE INDEX idx_sync_queue_entity ON sync_queue(entityType, entityId)');

    // Tabla de calendario (agregada en versión 2)
    await db.execute('''
      CREATE TABLE calendar_entries(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        recipeId TEXT NOT NULL,
        recipeTitle TEXT NOT NULL,
        recipeImageUrl TEXT NOT NULL,
        scheduledDate TEXT NOT NULL,
        mealType TEXT NOT NULL,
        notificationSent INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updatedAt TEXT NOT NULL,
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (recipeId) REFERENCES recipes(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_calendar_userId ON calendar_entries(userId)');
    await db.execute('CREATE INDEX idx_calendar_scheduledDate ON calendar_entries(scheduledDate)');

    // Tabla de productos (agregada en versión 3)
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        barcode TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        category TEXT NOT NULL,
        nutritionalInfo TEXT NOT NULL,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updatedAt TEXT NOT NULL,
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_products_userId ON products(userId)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar tabla de calendario
      await db.execute('''
        CREATE TABLE calendar_entries(
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          recipeId TEXT NOT NULL,
          recipeTitle TEXT NOT NULL,
          recipeImageUrl TEXT NOT NULL,
          scheduledDate TEXT NOT NULL,
          mealType TEXT NOT NULL,
          notificationSent INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updatedAt TEXT NOT NULL,
          deleted INTEGER DEFAULT 0,
          FOREIGN KEY (userId) REFERENCES users(id),
          FOREIGN KEY (recipeId) REFERENCES recipes(id)
        )
      ''');

      await db.execute('CREATE INDEX idx_calendar_userId ON calendar_entries(userId)');
      await db.execute('CREATE INDEX idx_calendar_scheduledDate ON calendar_entries(scheduledDate)');
    }

    if (oldVersion < 3) {
      // Agregar tabla de productos
      await db.execute('''
        CREATE TABLE products(
          id TEXT PRIMARY KEY,
          barcode TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          brand TEXT NOT NULL,
          imageUrl TEXT NOT NULL,
          category TEXT NOT NULL,
          nutritionalInfo TEXT NOT NULL,
          userId TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updatedAt TEXT NOT NULL,
          deleted INTEGER DEFAULT 0,
          FOREIGN KEY (userId) REFERENCES users(id)
        )
      ''');

      await db.execute('CREATE INDEX idx_products_userId ON products(userId)');
      await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    }
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Obtiene la ruta de la base de datos
  Future<String> getDatabasePath() async {
    final databasePath = await getDatabasesPath();
    return join(databasePath, 'nutricional.db');
  }

  /// Limpia todas las tablas (útil para testing)
  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('sync_queue');
    await db.delete('recipes');
    await db.delete('active_session');
    await db.delete('users');
  }

  /// Elimina la base de datos completa
  Future<void> deleteDatabase() async {
    final path = await getDatabasePath();
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}

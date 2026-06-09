// lib/data/repositories/local_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/helper_model.dart'; // Assuming models are similar to entities for now

class LocalDb {
  static final LocalDb _instance = LocalDb._internal();
  static Database? _database;

  factory LocalDb() => _instance;

  LocalDb._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await sqflite.getDatabasesPath(), 'roadside_help.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE helpers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        phoneNumber TEXT NOT NULL,
        sms_capable INTEGER NOT NULL,
        opening_hours TEXT,
        source TEXT NOT NULL,
        last_updated TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE problem_types (
        id TEXT PRIMARY KEY,
        label_key TEXT NOT NULL,
        mapped_types TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE config (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> setConfig(String key, String value) async {
    final db = await database;
    await db.insert(
      'config',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getConfig(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'config',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty ? result.first['value'] as String? : null;
  }
}

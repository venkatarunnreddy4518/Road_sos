// lib/data/repositories/helper_repository.dart
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/helper.dart';
import 'local_db.dart';

class HelperRepository {
  final LocalDb _db = LocalDb();

  Future<List<Helper>> getHelpersByType(HelperType type) async {
    final db = await _db.database;
    final typeString = type.toString().split('.').last;

    final List<Map<String, dynamic>> maps = await db.query(
      'helpers',
      where: 'type = ?',
      whereArgs: [typeString],
    );

    return maps.map((map) => Helper.fromMap(map)).toList();
  }

  Future<void> upsertHelper(Helper helper) async {
    final db = await _db.database;
    await db.insert(
      'helpers',
      helper.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> bulkInsertHelpers(List<Helper> helpers) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (var helper in helpers) {
        if (helper.source == HelperSource.THIRD_PARTY) {
          // Only insert third-party if curated doesn't exist
          final exists = await txn.query('helpers', where: 'id = ?', whereArgs: [helper.id]);
          if (exists.isEmpty) {
            await txn.insert('helpers', helper.toMap());
          }
        } else {
          // Curated always overrides
          await txn.insert(
            'helpers',
            helper.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FinanceDatabaseService {
  Database? _db;

  Future<void> initialize() async {
    if (kIsWeb || _db != null) {
      return;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String dbPath = await getDatabasesPath();
    final String path = p.join(dbPath, 'finance_data.db');

    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE app_state (
              id INTEGER PRIMARY KEY,
              payload TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<void> saveState(String payload) async {
    final Database? db = _db;
    if (db == null) {
      return;
    }

    await db.insert('app_state', <String, Object>{
      'id': 1,
      'payload': payload,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> loadState() async {
    final Database? db = _db;
    if (db == null) {
      return null;
    }

    final List<Map<String, Object?>> rows = await db.query(
      'app_state',
      where: 'id = ?',
      whereArgs: <Object>[1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final Object? payload = rows.first['payload'];
    return payload is String ? payload : null;
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/account_data.dart';

class AccountDatabaseService {
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
    final String path = p.join(dbPath, 'account_data.db');

    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE account (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL,
              password TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<void> upsertAccount(AccountData account) async {
    final Database? db = _db;
    if (db == null) {
      return;
    }

    await db.insert('account', <String, Object>{
      'id': 1,
      'name': account.name,
      'email': account.email,
      'password': account.password,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AccountData?> getAccount() async {
    final Database? db = _db;
    if (db == null) {
      return null;
    }

    final List<Map<String, Object?>> rows = await db.query(
      'account',
      where: 'id = ?',
      whereArgs: <Object>[1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final Map<String, Object?> row = rows.first;
    return AccountData(
      name: (row['name'] as String?) ?? 'User',
      email: (row['email'] as String?) ?? 'user@example.com',
      password: (row['password'] as String?) ?? '123456',
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

/// The wallet, recipe ownership and current preparation commit together.
class GameStorage {
  GameStorage(this.database);
  final Database database;

  static Future<GameStorage> open({
    DatabaseFactory? factory,
    String? databasePath,
  }) async {
    if (factory == null && (Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    }
    factory ??= databaseFactory;
    final location = databasePath ?? await _databaseLocation(factory);
    if (location != inMemoryDatabasePath) {
      await Directory(path.dirname(location)).create(recursive: true);
    }
    final db = await factory.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE saved_game (id INTEGER PRIMARY KEY CHECK (id = 1), snapshot TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE wallet (id INTEGER PRIMARY KEY CHECK (id = 1), cents INTEGER NOT NULL CHECK (cents >= 0))',
          );
          await db.execute(
            'CREATE TABLE purchased_recipes (recipe_id TEXT PRIMARY KEY)',
          );
        },
      ),
    );
    return GameStorage(db);
  }

  static Future<String> _databaseLocation(DatabaseFactory factory) async {
    if (Platform.isAndroid) {
      // Use SQLite's native directory without depending on path_provider/JNI.
      final directory = await factory.getDatabasesPath();
      final previous = path.join(
        path.dirname(directory),
        'files',
        'pizza_game.db',
      );
      if (await File(previous).exists()) return previous;
      return path.join(directory, 'pizza_game.db');
    }
    return path.join(
      (await getApplicationSupportDirectory()).path,
      'pizza_game.db',
    );
  }

  Future<String?> load() async {
    final rows = await database.query(
      'saved_game',
      where: 'id = ?',
      whereArgs: [1],
    );
    return rows.isEmpty ? null : rows.single['snapshot'] as String;
  }

  Future<void> save(String snapshot) async {
    final data = jsonDecode(snapshot) as Map<String, dynamic>;
    final game = data['game'] as Map<String, dynamic>;
    await database.transaction((txn) async {
      await txn.insert('saved_game', {
        'id': 1,
        'snapshot': snapshot,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('wallet', {
        'id': 1,
        'cents': game['coins'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('purchased_recipes');
      for (final id in (game['purchasedRecipes'] as List? ?? const [])) {
        await txn.insert('purchased_recipes', {'recipe_id': id});
      }
    });
  }

  Future<void> close() => database.close();
}

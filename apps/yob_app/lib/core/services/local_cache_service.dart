import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

/// Local SQLite cache for offline support.
/// Stores API responses keyed by endpoint.
class LocalCacheService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, 'yob_cache.db');

    return openDatabase(
      fullPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            method TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            body TEXT,
            created_at INTEGER NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              method TEXT NOT NULL,
              endpoint TEXT NOT NULL,
              body TEXT,
              created_at INTEGER NOT NULL,
              synced INTEGER DEFAULT 0
            )
          ''');
        }
      },
    );
  }

  // ── Cache Operations ──

  /// Store API response data for a given cache key.
  static Future<void> put(String key, dynamic data) async {
    final db = await database;
    await db.insert(
      'cache',
      {
        'key': key,
        'data': jsonEncode(data),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve cached data by key.
  /// Returns null if not found or if older than [maxAge].
  static Future<dynamic> get(
    String key, {
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final db = await database;
    final results = await db.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final row = results.first;
    final timestamp = row['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;

    if (age > maxAge.inMilliseconds) {
      // Expired — remove it
      await db.delete('cache', where: 'key = ?', whereArgs: [key]);
      return null;
    }

    return jsonDecode(row['data'] as String);
  }

  /// Remove a specific cache entry.
  static Future<void> remove(String key) async {
    final db = await database;
    await db.delete('cache', where: 'key = ?', whereArgs: [key]);
  }

  /// Clear all cached data.
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('cache');
  }

  // ── Sync Queue Operations ──

  /// Queue a write operation to be synced when back online.
  static Future<void> enqueueSync({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'method': method,
      'endpoint': endpoint,
      'body': body != null ? jsonEncode(body) : null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
  }

  /// Get all pending (un-synced) operations.
  static Future<List<Map<String, dynamic>>> getPendingSync() async {
    final db = await database;
    return db.query(
      'sync_queue',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  /// Mark a sync queue item as synced.
  static Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of pending sync operations.
  static Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE synced = 0',
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Clear completed sync items.
  static Future<void> clearSynced() async {
    final db = await database;
    await db.delete('sync_queue', where: 'synced = 1');
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'arangkada.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE hazard_reports (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            description TEXT,
            voice_note_path TEXT,
            created_at TEXT NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE recent_searches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            name TEXT,
            address TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            searched_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE saved_locations (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            address TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            icon TEXT DEFAULT 'star'
          )
        ''');

        await db.execute('''
          CREATE TABLE offline_regions (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            min_lat REAL NOT NULL,
            min_lng REAL NOT NULL,
            max_lat REAL NOT NULL,
            max_lng REAL NOT NULL,
            zoom_min REAL NOT NULL,
            zoom_max REAL NOT NULL,
            downloaded_at TEXT,
            size_bytes INTEGER DEFAULT 0,
            status TEXT DEFAULT 'pending'
          )
        ''');

        await db.execute('''
          CREATE TABLE landmark_rag (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            taglish_description TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            barangay TEXT,
            city TEXT,
            province TEXT
          )
        ''');

        await _createCachedRoutesTable(db);
        await _createRideLogTables(db);
        await _createCachedPoisTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCachedRoutesTable(db);
        }
        if (oldVersion < 3) {
          await _createRideLogTables(db);
        }
        if (oldVersion < 4) {
          await _createCachedPoisTable(db);
        }
      },
    );
  }

  static Future<void> _createCachedRoutesTable(Database db) async {
    await db.execute('''
      CREATE TABLE cached_routes (
        id TEXT PRIMARY KEY,
        origin_name TEXT,
        dest_name TEXT,
        route_json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createCachedPoisTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_pois (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        category TEXT NOT NULL,
        place_type TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cached_pois_location
      ON cached_pois (latitude, longitude)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cached_pois_category
      ON cached_pois (category)
    ''');
  }

  static Future<void> _createRideLogTables(Database db) async {
    await db.execute('''
      CREATE TABLE ride_logs (
        id TEXT PRIMARY KEY,
        platform TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        distance_km REAL DEFAULT 0,
        origin_lat REAL,
        origin_lng REAL,
        dest_lat REAL,
        dest_lng REAL,
        estimated_earning REAL DEFAULT 0,
        fuel_cost REAL DEFAULT 0,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE rider_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── Ride Logs ──
  static Future<void> insertRideLog(Map<String, dynamic> data) async {
    final db = await instance;
    await db.insert('ride_logs', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateRideLog(
      String id, Map<String, dynamic> data) async {
    final db = await instance;
    await db.update('ride_logs', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getRideLogs({
    String? since,
    String? until,
    int? limit,
  }) async {
    final db = await instance;
    String? where;
    List<dynamic>? whereArgs;
    if (since != null && until != null) {
      where = 'start_time >= ? AND start_time < ?';
      whereArgs = [since, until];
    } else if (since != null) {
      where = 'start_time >= ?';
      whereArgs = [since];
    }
    return db.query('ride_logs',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'start_time DESC',
        limit: limit);
  }

  static Future<void> deleteRideLog(String id) async {
    final db = await instance;
    await db.delete('ride_logs', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAllRideLogs({int? limit}) async {
    final db = await instance;
    return db.query('ride_logs', orderBy: 'start_time DESC', limit: limit);
  }

  // ── Rider Settings ──
  static Future<void> setRiderSetting(String key, String value) async {
    final db = await instance;
    await db.insert('rider_settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> getRiderSetting(String key) async {
    final db = await instance;
    final rows =
        await db.query('rider_settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  // ── Cached Routes ──
  static Future<void> cacheRoute(
      String id, String? originName, String? destName, String routeJson) async {
    final db = await instance;
    await db.insert(
      'cached_routes',
      {
        'id': id,
        'origin_name': originName,
        'dest_name': destName,
        'route_json': routeJson,
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final all = await db.query('cached_routes', orderBy: 'cached_at DESC');
    if (all.length > 5) {
      final toDelete = all.sublist(5);
      for (final row in toDelete) {
        await db.delete('cached_routes',
            where: 'id = ?', whereArgs: [row['id']]);
      }
    }
  }

  static Future<Map<String, dynamic>?> getCachedRoute(String id) async {
    final db = await instance;
    final rows =
        await db.query('cached_routes', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<List<Map<String, dynamic>>> getAllCachedRoutes() async {
    final db = await instance;
    return db.query('cached_routes', orderBy: 'cached_at DESC');
  }

  static Future<void> deleteCachedRoute(String id) async {
    final db = await instance;
    await db.delete('cached_routes', where: 'id = ?', whereArgs: [id]);
  }

  // ── Hazard Reports ──
  static Future<int> insertHazard(Map<String, dynamic> data) async {
    final db = await instance;
    return db.insert('hazard_reports', data);
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedHazards() async {
    final db = await instance;
    return db.query('hazard_reports',
        where: 'synced = ?', whereArgs: [0], limit: 50);
  }

  static Future<void> markHazardsSynced(List<String> ids) async {
    final db = await instance;
    final batch = db.batch();
    for (final id in ids) {
      batch.update('hazard_reports', {'synced': 1},
          where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getNearbyHazards(
      double lat, double lng, double radiusKm) async {
    final db = await instance;
    final delta = radiusKm / 111.0;
    return db.query(
      'hazard_reports',
      where:
          'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ? AND created_at > ?',
      whereArgs: [
        lat - delta,
        lat + delta,
        lng - delta,
        lng + delta,
        DateTime.now().subtract(const Duration(hours: 24)).toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );
  }

  // ── Recent Searches ──
  static Future<void> addRecentSearch(Map<String, dynamic> data) async {
    final db = await instance;
    await db.insert('recent_searches', data);
    await db.delete('recent_searches',
        where:
            'id NOT IN (SELECT id FROM recent_searches ORDER BY searched_at DESC LIMIT 20)');
  }

  static Future<List<Map<String, dynamic>>> getRecentSearches() async {
    final db = await instance;
    return db.query('recent_searches',
        orderBy: 'searched_at DESC', limit: 10);
  }

  // ── Saved Locations ──
  static Future<int> saveLocation(Map<String, dynamic> data) async {
    final db = await instance;
    return db.insert('saved_locations', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getSavedLocations() async {
    final db = await instance;
    return db.query('saved_locations');
  }

  static Future<int> deleteSavedLocation(String id) async {
    final db = await instance;
    return db.delete('saved_locations', where: 'id = ?', whereArgs: [id]);
  }
}

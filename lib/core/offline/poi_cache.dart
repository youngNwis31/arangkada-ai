import 'package:sqflite/sqflite.dart';
import '../../models/location_model.dart';
import '../database/local_database.dart';

class PoiCache {
  static Future<void> cachePois(
    List<LocationModel> pois, {
    required String category,
  }) async {
    if (pois.isEmpty) return;
    final db = await LocalDatabase.instance;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final poi in pois) {
      batch.insert(
        'cached_pois',
        {
          'name': poi.name ?? '',
          'address': poi.address ?? '',
          'latitude': poi.latitude,
          'longitude': poi.longitude,
          'category': category,
          'place_type': poi.placeType ?? '',
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<LocationModel>> searchOffline(String query) async {
    if (query.trim().length < 2) return [];
    final db = await LocalDatabase.instance;
    final q = '%${query.trim().toLowerCase()}%';

    final rows = await db.rawQuery('''
      SELECT DISTINCT name, address, latitude, longitude, place_type
      FROM cached_pois
      WHERE LOWER(name) LIKE ? OR LOWER(address) LIKE ?
      ORDER BY name
      LIMIT 20
    ''', [q, q]);

    final saved = await db.rawQuery('''
      SELECT name, address, latitude, longitude, 'saved' AS place_type
      FROM saved_locations
      WHERE LOWER(name) LIKE ? OR LOWER(address) LIKE ?
      LIMIT 10
    ''', [q, q]);

    final recent = await db.rawQuery('''
      SELECT name, address, latitude, longitude, 'recent' AS place_type
      FROM recent_searches
      WHERE LOWER(name) LIKE ? OR LOWER(query) LIKE ?
      ORDER BY searched_at DESC
      LIMIT 10
    ''', [q, q]);

    final seen = <String>{};
    final results = <LocationModel>[];

    for (final list in [rows, saved, recent]) {
      for (final row in list) {
        final key =
            '${(row['latitude'] as num).toStringAsFixed(4)},${(row['longitude'] as num).toStringAsFixed(4)}';
        if (seen.add(key)) {
          results.add(LocationModel(
            latitude: (row['latitude'] as num).toDouble(),
            longitude: (row['longitude'] as num).toDouble(),
            name: row['name'] as String?,
            address: row['address'] as String?,
            placeType: row['place_type'] as String?,
          ));
        }
      }
    }
    return results;
  }

  static Future<List<LocationModel>> getNearbyOffline({
    required double lat,
    required double lng,
    double radiusM = 1500,
    String? category,
  }) async {
    final db = await LocalDatabase.instance;
    final delta = radiusM / 111000;

    String where =
        'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?';
    final args = <dynamic>[
      lat - delta,
      lat + delta,
      lng - delta,
      lng + delta,
    ];

    if (category != null) {
      where += ' AND category = ?';
      args.add(category);
    }

    final rows = await db.query(
      'cached_pois',
      where: where,
      whereArgs: args,
      orderBy: 'name',
      limit: 60,
    );

    return rows
        .where((r) => (r['name'] as String?)?.isNotEmpty == true)
        .map((r) => LocationModel(
              latitude: (r['latitude'] as num).toDouble(),
              longitude: (r['longitude'] as num).toDouble(),
              name: r['name'] as String?,
              address: r['address'] as String?,
              placeType: r['place_type'] as String?,
            ))
        .toList();
  }

  static Future<int> get cachedCount async {
    final db = await LocalDatabase.instance;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM cached_pois');
    return (r.first['c'] as int?) ?? 0;
  }

  static Future<void> clearAll() async {
    final db = await LocalDatabase.instance;
    await db.delete('cached_pois');
  }
}

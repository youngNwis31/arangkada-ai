import '../../core/database/local_database.dart';
import '../../domain/entities/ride_log.dart';
import '../../domain/enums/ride_platform.dart';
import '../../domain/repositories/i_ride_log_repository.dart';

class SqliteRideLogRepository implements IRideLogRepository {
  @override
  Future<void> insert(RideLog log) =>
      LocalDatabase.insertRideLog(_toRow(log));

  @override
  Future<void> update(String id, Map<String, dynamic> data) =>
      LocalDatabase.updateRideLog(id, data);

  @override
  Future<void> delete(String id) => LocalDatabase.deleteRideLog(id);

  @override
  Future<List<RideLog>> getAll({int? limit}) async {
    final rows = await LocalDatabase.getAllRideLogs(limit: limit);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<RideLog>> getByRange({
    String? since,
    String? until,
    int? limit,
  }) async {
    final rows = await LocalDatabase.getRideLogs(
      since: since,
      until: until,
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Map<String, dynamic> _toRow(RideLog log) => {
        'id': log.id,
        'platform': log.platform.name,
        'start_time': log.startTime.toIso8601String(),
        'end_time': log.endTime?.toIso8601String(),
        'distance_km': log.distanceKm,
        'origin_lat': log.originLat,
        'origin_lng': log.originLng,
        'dest_lat': log.destLat,
        'dest_lng': log.destLng,
        'estimated_earning': log.estimatedEarning,
        'fuel_cost': log.fuelCost,
        'notes': log.notes,
      };

  RideLog _fromRow(Map<String, dynamic> row) => RideLog(
        id: row['id'] as String,
        platform: RidePlatform.values.firstWhere(
          (p) => p.name == row['platform'],
          orElse: () => RidePlatform.other,
        ),
        startTime: DateTime.parse(row['start_time'] as String),
        endTime: row['end_time'] != null
            ? DateTime.parse(row['end_time'] as String)
            : null,
        distanceKm: (row['distance_km'] as num?)?.toDouble() ?? 0,
        originLat: (row['origin_lat'] as num?)?.toDouble(),
        originLng: (row['origin_lng'] as num?)?.toDouble(),
        destLat: (row['dest_lat'] as num?)?.toDouble(),
        destLng: (row['dest_lng'] as num?)?.toDouble(),
        estimatedEarning: (row['estimated_earning'] as num?)?.toDouble() ?? 0,
        fuelCost: (row['fuel_cost'] as num?)?.toDouble() ?? 0,
        notes: row['notes'] as String?,
      );
}

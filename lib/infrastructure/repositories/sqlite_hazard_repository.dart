import '../../core/database/local_database.dart';
import '../../domain/entities/hazard.dart';
import '../../domain/enums/hazard_type.dart';
import '../../domain/repositories/i_hazard_repository.dart';

class SqliteHazardRepository implements IHazardRepository {
  @override
  Future<int> insert(Hazard hazard) => LocalDatabase.insertHazard({
        'id': hazard.id,
        'type': hazard.type.name,
        'latitude': hazard.latitude,
        'longitude': hazard.longitude,
        'description': hazard.description,
        'voice_note_path': hazard.voiceNotePath,
        'created_at': hazard.createdAt.toIso8601String(),
        'synced': hazard.synced ? 1 : 0,
      });

  @override
  Future<List<Hazard>> getNearby(
          double lat, double lng, double radiusKm) async {
    final rows = await LocalDatabase.getNearbyHazards(lat, lng, radiusKm);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Hazard>> getNearbyFloods(
          double lat, double lng, double radiusKm) async {
    final rows = await LocalDatabase.getNearbyFloodReports(lat, lng, radiusKm);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Hazard>> getUnsynced() async {
    final rows = await LocalDatabase.getUnsyncedHazards();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> markSynced(List<String> ids) =>
      LocalDatabase.markHazardsSynced(ids);

  Hazard _fromRow(Map<String, dynamic> row) => Hazard(
        id: row['id'] as String,
        type: HazardType.values.firstWhere((t) => t.name == row['type']),
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        description: row['description'] as String?,
        voiceNotePath: row['voice_note_path'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        synced: row['synced'] == 1,
      );
}

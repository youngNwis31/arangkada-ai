import 'package:uuid/uuid.dart';
import '../models/hazard_report.dart';
import '../core/database/local_database.dart';

class HazardService {
  static const _uuid = Uuid();

  static Future<HazardReport> reportHazard({
    required HazardType type,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    final report = HazardReport(
      id: _uuid.v4(),
      type: type,
      latitude: latitude,
      longitude: longitude,
      description: description,
      createdAt: DateTime.now(),
    );

    await LocalDatabase.insertHazard(report.toDb());
    return report;
  }

  static Future<List<HazardReport>> getNearbyHazards(
      double lat, double lng) async {
    final rows = await LocalDatabase.getNearbyHazards(lat, lng, 2.0);
    return rows.map((r) => HazardReport.fromDb(r)).toList();
  }
}

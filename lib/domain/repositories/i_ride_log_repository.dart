import '../entities/ride_log.dart';

abstract class IRideLogRepository {
  Future<void> insert(RideLog log);
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<List<RideLog>> getAll({int? limit});
  Future<List<RideLog>> getByRange({String? since, String? until, int? limit});
}

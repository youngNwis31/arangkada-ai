import '../entities/hazard.dart';

abstract class IHazardRepository {
  Future<int> insert(Hazard hazard);
  Future<List<Hazard>> getNearby(double lat, double lng, double radiusKm);
  Future<List<Hazard>> getNearbyFloods(double lat, double lng, double radiusKm);
  Future<List<Hazard>> getUnsynced();
  Future<void> markSynced(List<String> ids);
}

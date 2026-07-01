abstract class IRouteRepository {
  Future<void> cache(String id, String? originName, String? destName, String routeJson);
  Future<Map<String, dynamic>?> getCached(String id);
  Future<List<Map<String, dynamic>>> getAllCached();
  Future<void> deleteCached(String id);
}

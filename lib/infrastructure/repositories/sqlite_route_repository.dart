import '../../core/database/local_database.dart';
import '../../domain/repositories/i_route_repository.dart';

class SqliteRouteRepository implements IRouteRepository {
  @override
  Future<void> cache(
          String id, String? originName, String? destName, String routeJson) =>
      LocalDatabase.cacheRoute(id, originName, destName, routeJson);

  @override
  Future<Map<String, dynamic>?> getCached(String id) =>
      LocalDatabase.getCachedRoute(id);

  @override
  Future<List<Map<String, dynamic>>> getAllCached() =>
      LocalDatabase.getAllCachedRoutes();

  @override
  Future<void> deleteCached(String id) => LocalDatabase.deleteCachedRoute(id);
}

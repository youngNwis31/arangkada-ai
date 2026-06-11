import 'dart:convert';
import '../../models/route_model.dart';
import '../database/local_database.dart';

class RouteCache {
  static Future<void> cacheRoute(RouteModel route) async {
    final json = jsonEncode(route.toJson());
    await LocalDatabase.cacheRoute(
      route.id,
      route.origin.name,
      route.destination.name,
      json,
    );
  }

  static Future<RouteModel?> getRoute(String id) async {
    final row = await LocalDatabase.getCachedRoute(id);
    if (row == null) return null;
    final json = jsonDecode(row['route_json'] as String) as Map<String, dynamic>;
    return RouteModel.fromJson(json);
  }

  static Future<List<RouteModel>> getAllCached() async {
    final rows = await LocalDatabase.getAllCachedRoutes();
    return rows.map((row) {
      final json =
          jsonDecode(row['route_json'] as String) as Map<String, dynamic>;
      return RouteModel.fromJson(json);
    }).toList();
  }

  static Future<void> delete(String id) async {
    await LocalDatabase.deleteCachedRoute(id);
  }
}

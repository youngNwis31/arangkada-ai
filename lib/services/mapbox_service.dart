import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../utils/route_optimizer.dart';

class MapboxService {
  static Future<List<LocationModel>> searchPlaces(
    String query, {
    double? proximityLng,
    double? proximityLat,
  }) async {
    if (query.trim().isEmpty) return [];

    final params = <String, String>{
      'q': query,
      'format': 'json',
      'limit': '8',
      'countrycodes': 'ph',
      'addressdetails': '1',
    };

    if (proximityLng != null && proximityLat != null) {
      params['viewbox'] =
          '${proximityLng - 0.5},${proximityLat - 0.5},${proximityLng + 0.5},${proximityLat + 0.5}';
      params['bounded'] = '0';
    }

    final url = Uri.parse(AppConfig.nominatimSearchUrl)
        .replace(queryParameters: params);

    final response = await http.get(url, headers: {
      'User-Agent': 'ArangkadaAI/0.03 (rider-nav-app)',
    });
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as List;

    return data.map((item) {
      return LocationModel(
        longitude: double.parse(item['lon'] as String),
        latitude: double.parse(item['lat'] as String),
        name: item['display_name']?.toString().split(',').first,
        address: item['display_name'] as String?,
      );
    }).toList();
  }

  static Future<List<RouteModel>> getRoutes({
    required LocationModel origin,
    required LocationModel destination,
    String profile = 'driving',
  }) async {
    final coords =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';

    final url = Uri.parse(
      '${AppConfig.osrmDirectionsUrl}/$coords',
    ).replace(queryParameters: {
      'alternatives': 'true',
      'geometries': 'geojson',
      'overview': 'full',
      'steps': 'true',
    });

    final response = await http.get(url, headers: {
      'User-Agent': 'ArangkadaAI/0.03 (rider-nav-app)',
    });
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
    if (data['code'] != 'Ok') return [];
    final routes = data['routes'] as List;

    final models = <RouteModel>[];

    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      final geometry = route['geometry'];
      final coords = (geometry['coordinates'] as List)
          .map<List<double>>(
              (c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()])
          .toList();

      final legs = route['legs'] as List;
      final steps = <RouteStep>[];

      for (final leg in legs) {
        for (final step in (leg['steps'] as List)) {
          final m = step['maneuver'];
          final loc = m['location'] as List?;
          steps.add(RouteStep(
            instruction: step['name'] as String? ?? '',
            distance: (step['distance'] as num).toDouble(),
            duration: (step['duration'] as num).toDouble(),
            modifier: m['modifier'] as String?,
            maneuverType: m['type'] as String?,
            maneuverLng: loc != null ? (loc[0] as num).toDouble() : null,
            maneuverLat: loc != null ? (loc[1] as num).toDouble() : null,
          ));
        }
      }

      models.add(RouteModel(
        id: 'route_$i',
        origin: origin,
        destination: destination,
        coordinates: coords,
        distance: (route['distance'] as num).toDouble(),
        duration: (route['duration'] as num).toDouble(),
        congestionLevels: [],
        steps: steps,
        aiScore: 0,
        label: i == 0 ? 'Primary' : 'Alternative $i',
      ));
    }

    return RouteOptimizer.scoreAndRank(models);
  }
}

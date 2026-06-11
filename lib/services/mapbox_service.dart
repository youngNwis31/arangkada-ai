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
      'access_token': AppConfig.mapboxAccessToken,
      'limit': '8',
      'types': 'place,locality,neighborhood,address,poi',
      'country': 'PH',
    };

    if (proximityLng != null && proximityLat != null) {
      params['proximity'] = '$proximityLng,$proximityLat';
    }

    final url = Uri.parse(
      '${AppConfig.mapboxGeocodingUrl}/${Uri.encodeComponent(query)}.json',
    ).replace(queryParameters: params);

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
    final features = data['features'] as List;

    return features.map((f) {
      final center = f['center'] as List;
      return LocationModel(
        longitude: (center[0] as num).toDouble(),
        latitude: (center[1] as num).toDouble(),
        name: f['text'] as String?,
        address: f['place_name'] as String?,
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
      '${AppConfig.mapboxDirectionsUrl}/$profile/$coords',
    ).replace(queryParameters: {
      'access_token': AppConfig.mapboxAccessToken,
      'alternatives': 'true',
      'geometries': 'geojson',
      'overview': 'full',
      'steps': 'true',
      'annotations': 'congestion,duration',
    });

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
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
      var congestion = <String>[];

      for (final leg in legs) {
        if (leg['annotation']?['congestion'] != null) {
          congestion = (leg['annotation']['congestion'] as List)
              .map((c) => c.toString())
              .toList();
        }
        for (final step in (leg['steps'] as List)) {
          final m = step['maneuver'];
          final loc = m['location'] as List?;
          steps.add(RouteStep(
            instruction: m['instruction'] as String? ?? '',
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
        congestionLevels: congestion,
        steps: steps,
        aiScore: 0,
        label: i == 0 ? 'Primary' : 'Alternative $i',
      ));
    }

    return RouteOptimizer.scoreAndRank(models);
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../core/offline/poi_cache.dart';
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

    try {
      final results = await _searchOnline(query,
          proximityLng: proximityLng, proximityLat: proximityLat);
      if (results.isNotEmpty) {
        PoiCache.cachePois(results, category: 'search');
      }
      return results;
    } catch (e) {
      debugPrint('Search offline fallback: $e');
      return PoiCache.searchOffline(query);
    }
  }

  static Future<List<LocationModel>> _searchOnline(
    String query, {
    double? proximityLng,
    double? proximityLat,
  }) async {
    final params = <String, String>{
      'q': query,
      'format': 'json',
      'limit': '10',
      'countrycodes': 'ph',
      'addressdetails': '1',
      'dedupe': '1',
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
    }).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as List;

    return data.map((item) {
      final addr = item['address'] as Map<String, dynamic>? ?? {};
      final type = item['type'] as String? ?? '';
      final category = item['class'] as String? ?? '';

      final placeName = _extractName(item, addr, type);
      final addressLine = _buildAddress(addr, placeName);

      return LocationModel(
        longitude: double.parse(item['lon'] as String),
        latitude: double.parse(item['lat'] as String),
        name: placeName,
        address: addressLine,
        placeType: _classifyType(category, type),
      );
    }).toList();
  }

  static String _extractName(
      Map<String, dynamic> item, Map<String, dynamic> addr, String type) {
    for (final key in [
      type,
      'amenity',
      'building',
      'shop',
      'tourism',
      'leisure',
      'office',
      'craft',
      'aeroway',
      'railway',
      'highway',
    ]) {
      if (addr.containsKey(key) && addr[key] != null) {
        return addr[key].toString();
      }
    }
    final display = item['display_name']?.toString() ?? '';
    return display.split(',').first.trim();
  }

  static String _buildAddress(Map<String, dynamic> addr, String placeName) {
    final parts = <String>[];

    final houseNumber = addr['house_number']?.toString();
    final road = addr['road']?.toString();
    if (road != null) {
      parts.add(houseNumber != null ? '$houseNumber $road' : road);
    }

    for (final key in [
      'neighbourhood',
      'suburb',
      'village',
      'town',
      'city_district',
      'city',
      'municipality',
    ]) {
      final v = addr[key]?.toString();
      if (v != null && v != placeName && !parts.contains(v)) {
        parts.add(v);
        if (parts.length >= 3) break;
      }
    }

    final province = addr['state']?.toString() ?? addr['province']?.toString();
    if (province != null && !parts.contains(province)) {
      parts.add(province);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Philippines';
  }

  static String _classifyType(String category, String type) {
    if (category == 'amenity') {
      if (const {'restaurant', 'fast_food', 'cafe', 'food_court'}
          .contains(type)) return 'food';
      if (const {'hospital', 'clinic', 'pharmacy', 'doctors'}
          .contains(type)) return 'health';
      if (const {'school', 'university', 'college', 'library'}
          .contains(type)) return 'education';
      if (const {'bank', 'atm'}.contains(type)) return 'finance';
      if (const {'place_of_worship', 'church'}.contains(type)) return 'worship';
      if (const {'fuel', 'charging_station'}.contains(type)) return 'fuel';
      if (const {'police', 'fire_station'}.contains(type)) return 'emergency';
      return 'amenity';
    }
    if (category == 'shop') return 'shop';
    if (category == 'tourism') return 'landmark';
    if (category == 'building') return 'building';
    if (category == 'highway') return 'road';
    if (category == 'place') return 'place';
    if (category == 'office') return 'office';
    if (const {'aeroway', 'railway', 'public_transport'}.contains(category)) {
      return 'transport';
    }
    return 'place';
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

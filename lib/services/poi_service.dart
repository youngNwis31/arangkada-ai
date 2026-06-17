import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/offline/poi_cache.dart';
import '../models/location_model.dart';

enum PoiCategory {
  cafe('Cafe', '☕', 'amenity', 'cafe'),
  restaurant('Restaurant', '🍽️', 'amenity', 'restaurant'),
  fastFood('Fast Food', '🍔', 'amenity', 'fast_food'),
  gasStation('Gas Station', '⛽', 'amenity', 'fuel'),
  bank('Bank', '🏦', 'amenity', 'bank'),
  atm('ATM', '💳', 'amenity', 'atm'),
  pharmacy('Pharmacy', '💊', 'amenity', 'pharmacy'),
  hospital('Hospital', '🏥', 'amenity', 'hospital'),
  convenience('Store', '🏪', 'shop', 'convenience'),
  supermarket('Supermarket', '🛒', 'shop', 'supermarket'),
  school('School', '🏫', 'amenity', 'school'),
  church('Church', '⛪', 'amenity', 'place_of_worship'),
  police('Police', '👮', 'amenity', 'police'),
  parking('Parking', '🅿️', 'amenity', 'parking');

  final String label;
  final String emoji;
  final String osmKey;
  final String osmValue;
  const PoiCategory(this.label, this.emoji, this.osmKey, this.osmValue);
}

class PoiService {
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const _defaultRadius = 1500; // meters

  static Future<List<LocationModel>> fetchNearby({
    required double lat,
    required double lng,
    required List<PoiCategory> categories,
    int radius = _defaultRadius,
  }) async {
    if (categories.isEmpty) return [];

    final filters = categories.map((c) {
      return 'node["${c.osmKey}"="${c.osmValue}"](around:$radius,$lat,$lng);';
    }).join('');

    final query = '[out:json][timeout:10];($filters);out body 60;';

    try {
      final url = Uri.parse(_overpassUrl).replace(
        queryParameters: {'data': query},
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'ArangkadaAI/0.03 (rider-nav-app)',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return _offlineFallback(lat: lat, lng: lng, categories: categories, radius: radius);
      }

      final data = json.decode(response.body);
      final elements = data['elements'] as List? ?? [];

      final results = elements.map<LocationModel?>((e) {
        final tags = e['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name'] as String?;
        if (name == null || name.isEmpty) return null;

        final elLat = (e['lat'] as num?)?.toDouble();
        final elLng = (e['lon'] as num?)?.toDouble();
        if (elLat == null || elLng == null) return null;

        final type = _classifyTags(tags);
        final address = _buildPoiAddress(tags);

        return LocationModel(
          latitude: elLat,
          longitude: elLng,
          name: name,
          address: address,
          placeType: type,
        );
      }).whereType<LocationModel>().toList();

      for (final cat in categories) {
        final catResults = results.where((r) =>
            r.placeType == _classifyFromCategory(cat)).toList();
        if (catResults.isNotEmpty) {
          PoiCache.cachePois(catResults, category: cat.osmValue);
        }
      }
      if (categories.length > 1 && results.isNotEmpty) {
        PoiCache.cachePois(results, category: 'mixed');
      }

      return results;
    } catch (e) {
      debugPrint('POI fetch error: $e — falling back to cache');
      return _offlineFallback(lat: lat, lng: lng, categories: categories, radius: radius);
    }
  }

  static Future<List<LocationModel>> fetchByCategory({
    required double lat,
    required double lng,
    required PoiCategory category,
    int radius = 2000,
  }) async {
    return fetchNearby(
      lat: lat,
      lng: lng,
      categories: [category],
      radius: radius,
    );
  }

  static Future<List<LocationModel>> fetchAllNearby({
    required double lat,
    required double lng,
    int radius = 800,
  }) async {
    return fetchNearby(
      lat: lat,
      lng: lng,
      categories: [
        PoiCategory.cafe,
        PoiCategory.restaurant,
        PoiCategory.fastFood,
        PoiCategory.gasStation,
        PoiCategory.bank,
        PoiCategory.convenience,
        PoiCategory.pharmacy,
      ],
      radius: radius,
    );
  }

  static String _classifyTags(Map<String, dynamic> tags) {
    final amenity = tags['amenity'] as String? ?? '';
    final shop = tags['shop'] as String? ?? '';

    if ({'cafe', 'restaurant', 'fast_food', 'food_court'}.contains(amenity)) {
      return 'food';
    }
    if ({'hospital', 'clinic', 'pharmacy', 'doctors'}.contains(amenity)) {
      return 'health';
    }
    if ({'school', 'university', 'college', 'library'}.contains(amenity)) {
      return 'education';
    }
    if ({'bank', 'atm'}.contains(amenity)) return 'finance';
    if (amenity == 'place_of_worship') return 'worship';
    if (amenity == 'fuel') return 'fuel';
    if ({'police', 'fire_station'}.contains(amenity)) return 'emergency';
    if (amenity == 'parking') return 'parking';
    if (shop.isNotEmpty) return 'shop';
    return 'amenity';
  }

  static Future<List<LocationModel>> _offlineFallback({
    required double lat,
    required double lng,
    required List<PoiCategory> categories,
    required int radius,
  }) async {
    if (categories.length == 1) {
      return PoiCache.getNearbyOffline(
        lat: lat,
        lng: lng,
        radiusM: radius.toDouble(),
        category: categories.first.osmValue,
      );
    }
    return PoiCache.getNearbyOffline(
      lat: lat,
      lng: lng,
      radiusM: radius.toDouble(),
    );
  }

  static String _classifyFromCategory(PoiCategory cat) {
    return switch (cat) {
      PoiCategory.cafe || PoiCategory.restaurant || PoiCategory.fastFood => 'food',
      PoiCategory.hospital || PoiCategory.pharmacy => 'health',
      PoiCategory.school => 'education',
      PoiCategory.bank || PoiCategory.atm => 'finance',
      PoiCategory.church => 'worship',
      PoiCategory.gasStation => 'fuel',
      PoiCategory.police => 'emergency',
      PoiCategory.parking => 'parking',
      PoiCategory.convenience || PoiCategory.supermarket => 'shop',
    };
  }

  static String _buildPoiAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final street = tags['addr:street'] as String?;
    final houseNum = tags['addr:housenumber'] as String?;
    if (street != null) {
      parts.add(houseNum != null ? '$houseNum $street' : street);
    }
    final city = tags['addr:city'] as String?;
    if (city != null) parts.add(city);
    final cuisine = tags['cuisine'] as String?;
    if (cuisine != null && parts.isEmpty) {
      parts.add(cuisine.replaceAll(';', ', '));
    }
    final brand = tags['brand'] as String?;
    if (brand != null && parts.isEmpty) parts.add(brand);
    return parts.isNotEmpty ? parts.join(', ') : '';
  }
}

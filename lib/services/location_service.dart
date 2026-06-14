import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../config/app_config.dart';

class LocationService {
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  static bool _isInPhilippines(double lat, double lng) {
    return lat >= 4.5 && lat <= 21.5 && lng >= 116.0 && lng <= 127.0;
  }

  static Future<LocationModel> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return _defaultLocation();

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      if (!_isInPhilippines(position.latitude, position.longitude)) {
        return _defaultLocation();
      }

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return _defaultLocation();
    }
  }

  static Stream<Position> getPositionStream({int intervalMs = 3000}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        timeLimit: Duration(milliseconds: intervalMs),
      ),
    );
  }

  static LocationModel _defaultLocation() => const LocationModel(
        latitude: AppConfig.defaultLat,
        longitude: AppConfig.defaultLng,
        name: 'Manila',
      );
}

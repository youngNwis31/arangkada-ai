class AppConfig {
  AppConfig._();

  static const String appName = 'Arangkada AI';
  static const String appVersion = 'v0.01';
  static const String developer = 'James Earl Medrano';
  static const String appTagline = 'Your 24/7 Rider Road Assistant';

  // Mapbox — Replace with your free token from mapbox.com
  static const String mapboxAccessToken = 'YOUR_MAPBOX_ACCESS_TOKEN';
  static const String mapboxStyleDark =
      'mapbox://styles/mapbox/navigation-night-v1';
  static const String mapboxDirectionsUrl =
      'https://api.mapbox.com/directions/v5/mapbox';
  static const String mapboxGeocodingUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  // Default location: Manila, Philippines
  static const double defaultLat = 14.5995;
  static const double defaultLng = 120.9842;
  static const double defaultZoom = 14.0;

  // AI Route Scoring Weights
  static const double weightDistance = 0.3;
  static const double weightDuration = 0.5;
  static const double weightCongestion = 0.2;

  // Battery Saver Thresholds
  static const double stationaryThreshold = 0.5; // m/s² acceleration delta
  static const int stationaryGpsIntervalMs = 30000; // 30s when stopped
  static const int movingGpsIntervalMs = 3000; // 3s when moving

  // Offline Sync
  static const int syncBatchSize = 50;
  static const int maxOfflineHazards = 500;

  // Navigation Thresholds
  static const double navStepAdvanceMeters = 30.0;
  static const double navOffRouteMeters = 100.0;
  static const double navVoiceAnnounce500m = 500.0;
  static const double navVoiceAnnounce200m = 200.0;
  static const double navVoiceAnnounceNow = 40.0;
  static const double navLowSpeedThreshold = 2.0; // m/s (~7 km/h)
  static const int navMaxCachedRoutes = 5;

  // Firebase Free Tier Guardrails
  static const int maxFirestoreWritesPerDay = 20000;
  static const int maxFirestoreReadsPerDay = 50000;
}

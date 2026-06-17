class AppConfig {
  AppConfig._();

  static const String appName = 'Arangkada AI';
  static const String appVersion = 'v0.04';
  static const String developer = 'James Earl Medrano';
  static const String appTagline = 'Your 24/7 Rider Road Assistant';

  // Map tiles — free, no API key required
  static const String osmTileUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
  static const String osmTileUrlDark =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

  // OSRM Directions — free, no API key
  static const String osrmDirectionsUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // Nominatim Geocoding — free, no API key
  static const String nominatimSearchUrl =
      'https://nominatim.openstreetmap.org/search';

  // Default location: Manila, Philippines
  static const double defaultLat = 14.5995;
  static const double defaultLng = 120.9842;
  static const double defaultZoom = 14.0;

  // AI Route Scoring Weights
  static const double weightDistance = 0.3;
  static const double weightDuration = 0.5;
  static const double weightCongestion = 0.2;

  // Battery Saver Thresholds
  static const double stationaryThreshold = 0.5;
  static const int stationaryGpsIntervalMs = 30000;
  static const int movingGpsIntervalMs = 3000;

  // Offline Sync
  static const int syncBatchSize = 50;
  static const int maxOfflineHazards = 500;

  // Navigation Thresholds
  static const double navStepAdvanceMeters = 30.0;
  static const double navOffRouteMeters = 100.0;
  static const double navVoiceAnnounce500m = 500.0;
  static const double navVoiceAnnounce200m = 200.0;
  static const double navVoiceAnnounceNow = 40.0;
  static const double navLowSpeedThreshold = 2.0;
  static const int navMaxCachedRoutes = 5;

  // Offline Map Tile Download
  static const double metroManilaMinLat = 14.35;
  static const double metroManilaMaxLat = 14.78;
  static const double metroManilaMinLng = 120.85;
  static const double metroManilaMaxLng = 121.15;
  static const int tileDownloadMinZoom = 10;
  static const int tileDownloadMaxZoom = 17;

  // On-Device LLM (Gemma 2B)
  static const String gemmaModelUrl =
      'https://huggingface.co/lmstudio-community/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf';
  static const String gemmaModelFilename = 'gemma-2-2b-it-Q4_K_M.gguf';
  static const int gemmaModelSizeBytes = 1500000000; // ~1.5 GB
  static const int llmMaxTokens = 256;
  static const int llmTimeoutSeconds = 30;

  // Firebase Free Tier Guardrails
  static const int maxFirestoreWritesPerDay = 20000;
  static const int maxFirestoreReadsPerDay = 50000;
}

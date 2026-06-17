import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_config.dart';

class TileCacheManager extends ChangeNotifier {
  static const _storeName = 'cartodb_voyager';

  bool _isDownloading = false;
  double _progress = 0;
  int _downloadedTiles = 0;
  int _totalTiles = 0;
  bool _isInitialized = false;
  double _storeSizeKiB = 0;
  int _storeTileCount = 0;

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  int get downloadedTiles => _downloadedTiles;
  int get totalTiles => _totalTiles;
  bool get isInitialized => _isInitialized;
  double get storeSizeMB => _storeSizeKiB / 1024;
  int get storeTileCount => _storeTileCount;
  bool get hasDownload => _storeTileCount > 0;

  FMTCStore get store => const FMTCStore(_storeName);

  static Future<void> initBackend() async {
    await FMTCObjectBoxBackend().initialise();
  }

  Future<void> init() async {
    final exists = await store.manage.ready;
    if (!exists) {
      await store.manage.create();
    }
    await refreshStats();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> refreshStats() async {
    try {
      final stats = await store.stats.all;
      _storeSizeKiB = stats.size;
      _storeTileCount = stats.length;
      notifyListeners();
    } catch (_) {}
  }

  FMTCTileProvider get tileProvider => FMTCTileProvider(
        stores: {_storeName: BrowseStoreStrategy.readUpdateCreate},
        loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      );

  int estimateTileCount(LatLngBounds bounds, int minZoom, int maxZoom) {
    int total = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final n = 1 << z;
      final xMin = _lngToTileX(bounds.west, n);
      final xMax = _lngToTileX(bounds.east, n);
      final yMin = _latToTileY(bounds.north, n);
      final yMax = _latToTileY(bounds.south, n);
      total += (xMax - xMin + 1) * (yMax - yMin + 1);
    }
    return total;
  }

  int _lngToTileX(double lng, int n) => ((lng + 180) / 360 * n).floor();

  int _latToTileY(double lat, int n) {
    final latRad = lat * math.pi / 180;
    return ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            n)
        .floor()
        .clamp(0, n - 1);
  }

  Future<void> downloadMetroManila() async {
    if (_isDownloading) return;

    _isDownloading = true;
    _progress = 0;
    _downloadedTiles = 0;
    notifyListeners();

    final region = RectangleRegion(
      LatLngBounds(
        LatLng(AppConfig.metroManilaMinLat, AppConfig.metroManilaMinLng),
        LatLng(AppConfig.metroManilaMaxLat, AppConfig.metroManilaMaxLng),
      ),
    );

    final tileLayer = TileLayer(
      urlTemplate: AppConfig.osmTileUrl,
      userAgentPackageName: 'com.arangkada.arangkadaAi',
      maxZoom: 19,
    );

    final downloadable = region.toDownloadable(
      minZoom: AppConfig.tileDownloadMinZoom,
      maxZoom: AppConfig.tileDownloadMaxZoom,
      options: tileLayer,
    );

    final (:tileEvents, :downloadProgress) = store.download.startForeground(
      region: downloadable,
      parallelThreads: 3,
      skipExistingTiles: true,
      rateLimit: 100,
    );

    await for (final event in downloadProgress) {
      _downloadedTiles = event.attemptedTilesCount;
      _totalTiles = event.maxTilesCount;
      _progress = event.percentageProgress / 100;
      notifyListeners();
    }

    _isDownloading = false;
    await refreshStats();
    notifyListeners();
  }

  Future<void> cancelDownload() async {
    await store.download.cancel();
    _isDownloading = false;
    await refreshStats();
    notifyListeners();
  }

  Future<void> deleteCache() async {
    await store.manage.reset();
    _storeSizeKiB = 0;
    _storeTileCount = 0;
    notifyListeners();
  }
}

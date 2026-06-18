import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../core/database/local_database.dart';
import '../models/ride_log_model.dart';
import 'location_service.dart';

class RideLogger extends ChangeNotifier {
  RideLog? _activeRide;
  RidePlatform _selectedPlatform = RidePlatform.grab;
  List<RideLog> _todayLogs = [];
  List<RideLog> _weekLogs = [];
  List<RideLog> _allLogs = [];
  double _fuelPricePerLiter = 65.0;
  double _vehicleKmPerLiter = 40.0;
  StreamSubscription<Position>? _gpsSub;
  Position? _lastPos;
  double _trackedDistanceKm = 0;

  RideLog? get activeRide => _activeRide;
  bool get isRiding => _activeRide != null;
  RidePlatform get selectedPlatform => _selectedPlatform;
  List<RideLog> get todayLogs => _todayLogs;
  List<RideLog> get weekLogs => _weekLogs;
  List<RideLog> get allLogs => _allLogs;
  double get fuelPricePerLiter => _fuelPricePerLiter;
  double get vehicleKmPerLiter => _vehicleKmPerLiter;

  double get todayEarnings =>
      _todayLogs.fold(0, (sum, r) => sum + r.estimatedEarning);
  double get todayFuelCost =>
      _todayLogs.fold(0, (sum, r) => sum + r.fuelCost);
  double get todayDistance =>
      _todayLogs.fold(0, (sum, r) => sum + r.distanceKm);
  int get todayRideCount => _todayLogs.length;

  Duration get todayRideDuration =>
      _todayLogs.fold(Duration.zero, (sum, r) => sum + r.duration);

  double get weekEarnings =>
      _weekLogs.fold(0, (sum, r) => sum + r.estimatedEarning);
  double get weekFuelCost =>
      _weekLogs.fold(0, (sum, r) => sum + r.fuelCost);
  double get weekDistance =>
      _weekLogs.fold(0, (sum, r) => sum + r.distanceKm);

  Future<void> init() async {
    final fuelStr = await LocalDatabase.getRiderSetting('fuel_price_per_liter');
    if (fuelStr != null) _fuelPricePerLiter = double.tryParse(fuelStr) ?? 65.0;

    final kmStr = await LocalDatabase.getRiderSetting('vehicle_km_per_liter');
    if (kmStr != null) _vehicleKmPerLiter = double.tryParse(kmStr) ?? 40.0;

    await refreshLogs();
  }

  Future<void> refreshLogs() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));

    final todayRows = await LocalDatabase.getRideLogs(
        since: todayStart.toIso8601String());
    _todayLogs = todayRows.map((r) => RideLog.fromDb(r)).toList();

    final weekRows = await LocalDatabase.getRideLogs(
        since: weekStart.toIso8601String());
    _weekLogs = weekRows.map((r) => RideLog.fromDb(r)).toList();

    final allRows = await LocalDatabase.getAllRideLogs(limit: 500);
    _allLogs = allRows.map((r) => RideLog.fromDb(r)).toList();

    notifyListeners();
  }

  void selectPlatform(RidePlatform platform) {
    _selectedPlatform = platform;
    notifyListeners();
  }

  Future<void> startRide() async {
    if (isRiding) return;

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {}

    _activeRide = RideLog(
      id: const Uuid().v4(),
      platform: _selectedPlatform,
      startTime: DateTime.now(),
      originLat: pos?.latitude,
      originLng: pos?.longitude,
    );
    _trackedDistanceKm = 0;
    _lastPos = pos;

    await LocalDatabase.insertRideLog(_activeRide!.toDb());
    notifyListeners();

    _gpsSub = LocationService.getPositionStream(intervalMs: 5000).listen(
      _onGpsUpdate,
      onError: (_) {},
    );
  }

  Future<void> endRide({double? earning}) async {
    if (!isRiding) return;

    _gpsSub?.cancel();
    _gpsSub = null;

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {}

    final fuelCost =
        (_trackedDistanceKm / _vehicleKmPerLiter) * _fuelPricePerLiter;

    _activeRide = _activeRide!.copyWith(
      endTime: DateTime.now(),
      distanceKm: _trackedDistanceKm,
      destLat: pos?.latitude,
      destLng: pos?.longitude,
      estimatedEarning: earning ?? 0,
      fuelCost: fuelCost,
    );

    await LocalDatabase.updateRideLog(_activeRide!.id, _activeRide!.toDb());
    _activeRide = null;
    _lastPos = null;

    await refreshLogs();
  }

  void _onGpsUpdate(Position pos) {
    if (_lastPos != null) {
      final d = _haversineKm(
          _lastPos!.latitude, _lastPos!.longitude, pos.latitude, pos.longitude);
      if (d > 0.005 && d < 2.0) {
        _trackedDistanceKm += d;
      }
    }
    _lastPos = pos;
  }

  Future<void> setFuelPrice(double price) async {
    _fuelPricePerLiter = price;
    await LocalDatabase.setRiderSetting(
        'fuel_price_per_liter', price.toString());
    notifyListeners();
  }

  Future<void> setVehicleEfficiency(double kmPerLiter) async {
    _vehicleKmPerLiter = kmPerLiter;
    await LocalDatabase.setRiderSetting(
        'vehicle_km_per_liter', kmPerLiter.toString());
    notifyListeners();
  }

  Map<int, int> get weeklyRideCounts {
    final counts = <int, int>{};
    for (int i = 1; i <= 7; i++) {
      counts[i] = 0;
    }
    for (final ride in _weekLogs) {
      final day = ride.startTime.weekday;
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> logQuickRide({required String platform, required double earning}) async {
    final p = RidePlatform.values.firstWhere(
      (e) => e.name.toLowerCase() == platform.toLowerCase(),
      orElse: () => RidePlatform.grab,
    );
    final ride = RideLog(
      id: const Uuid().v4(),
      platform: p,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      estimatedEarning: earning,
    );
    await LocalDatabase.insertRideLog(ride.toDb());
    await refreshLogs();
  }

  Map<RidePlatform, double> get earningsByPlatform {
    final map = <RidePlatform, double>{};
    for (final ride in _weekLogs) {
      map[ride.platform] =
          (map[ride.platform] ?? 0) + ride.estimatedEarning;
    }
    return map;
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }
}

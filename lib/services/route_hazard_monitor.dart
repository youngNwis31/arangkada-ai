import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/hazard_report.dart';
import 'ai/voice_service.dart';
import 'hazard_service.dart';
import 'navigation_provider.dart';

class RouteHazardMonitor extends ChangeNotifier {
  final NavigationProvider _nav;
  Timer? _scanTimer;
  bool _wasNavigating = false;
  HazardReport? _activeAlert;
  bool _showBanner = false;
  final Set<String> _alertedIds = {};

  RouteHazardMonitor(this._nav) {
    _nav.addListener(_onNavChange);
  }

  HazardReport? get activeAlert => _activeAlert;
  bool get showBanner => _showBanner;
  bool get isSevere =>
      _activeAlert != null &&
      (_activeAlert!.type == HazardType.roadClosure ||
          _activeAlert!.type == HazardType.floodImpassable ||
          _activeAlert!.type == HazardType.accident);

  void _onNavChange() {
    final navigating = _nav.isNavigating;
    if (navigating && !_wasNavigating) {
      _startScanning();
    } else if (!navigating && _wasNavigating) {
      _stopScanning();
    }
    _wasNavigating = navigating;
  }

  void _startScanning() {
    _alertedIds.clear();
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 30), (_) => _scan());
    _scan();
  }

  void _stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _activeAlert = null;
    _showBanner = false;
    _alertedIds.clear();
    notifyListeners();
  }

  Future<void> _scan() async {
    final engine = _nav.navEngine;
    if (!engine.isNavigating) return;

    final pos = engine.lastPosition;
    if (pos == null) return;

    final route = engine.route;
    if (route == null) return;

    final ahead = _getPointsAhead(
        pos.latitude, pos.longitude, route.coordinates, 1000);
    if (ahead.isEmpty) return;

    final hazards = <HazardReport>{};
    final step = (ahead.length / 5).ceil().clamp(1, ahead.length);
    for (int i = 0; i < ahead.length; i += step) {
      final coord = ahead[i];
      final nearby = await HazardService.getNearbyHazards(coord[1], coord[0]);
      hazards.addAll(nearby);
    }

    if (hazards.isEmpty) return;

    for (final h in hazards) {
      if (_alertedIds.contains(h.id)) continue;
      _alertedIds.add(h.id);

      final dist = _haversineM(
          pos.latitude, pos.longitude, h.latitude, h.longitude);
      if (dist > 1000) continue;

      _activeAlert = h;
      _showBanner = true;
      notifyListeners();

      final distText = dist >= 1000
          ? '${(dist / 1000).toStringAsFixed(1)} kilometers'
          : '${dist.toInt()} meters';

      if (isSevere) {
        await VoiceService.speak(
            'Warning! ${h.type.tagalog} $distText ahead. Gusto mo mag-reroute?');
      } else {
        await VoiceService.speak(
            'Ingat! ${h.type.tagalog} $distText ahead.');
      }

      Future.delayed(const Duration(seconds: 10), () {
        if (_activeAlert?.id == h.id) {
          _showBanner = false;
          notifyListeners();
        }
      });

      break;
    }
  }

  List<List<double>> _getPointsAhead(
      double lat, double lng, List<List<double>> coords, double maxDist) {
    int closestIdx = 0;
    double closestDist = double.infinity;
    for (int i = 0; i < coords.length; i++) {
      final d = _haversineM(lat, lng, coords[i][1], coords[i][0]);
      if (d < closestDist) {
        closestDist = d;
        closestIdx = i;
      }
    }

    final result = <List<double>>[];
    double accumulated = 0;
    for (int i = closestIdx; i < coords.length && accumulated < maxDist; i++) {
      result.add(coords[i]);
      if (i > closestIdx) {
        accumulated += _haversineM(
            coords[i - 1][1], coords[i - 1][0], coords[i][1], coords[i][0]);
      }
    }
    return result;
  }

  void dismissBanner() {
    _showBanner = false;
    _activeAlert = null;
    notifyListeners();
  }

  static double _haversineM(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  @override
  void dispose() {
    _nav.removeListener(_onNavChange);
    _scanTimer?.cancel();
    super.dispose();
  }
}

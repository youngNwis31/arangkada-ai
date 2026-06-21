import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../models/route_model.dart';
import '../core/offline/route_cache.dart';
import 'ai/voice_service.dart';
import 'location_service.dart';

enum NavState { idle, navigating, offRoute, arrived }

class OfflineNavEngine extends ChangeNotifier {
  RouteModel? _route;
  int _currentStepIndex = 0;
  NavState _state = NavState.idle;
  Position? _lastPosition;
  double _distanceToNextStep = 0;
  double _totalRemainingDistance = 0;
  double _totalRemainingDuration = 0;
  double _speedMs = 0;
  StreamSubscription<Position>? _gpsSub;
  bool _voiceEnabled = true;

  final Set<String> _announcedDistances = {};

  RouteModel? get route => _route;
  int get currentStepIndex => _currentStepIndex;
  NavState get state => _state;
  Position? get lastPosition => _lastPosition;
  double get distanceToNextStep => _distanceToNextStep;
  double get totalRemainingDistance => _totalRemainingDistance;
  double get totalRemainingDuration => _totalRemainingDuration;
  double get speedMs => _speedMs;
  bool get voiceEnabled => _voiceEnabled;
  bool get isNavigating => _state == NavState.navigating || _state == NavState.offRoute;

  RouteStep? get currentStep =>
      _route != null && _currentStepIndex < _route!.steps.length
          ? _route!.steps[_currentStepIndex]
          : null;

  RouteStep? get nextStep =>
      _route != null && _currentStepIndex + 1 < _route!.steps.length
          ? _route!.steps[_currentStepIndex + 1]
          : null;

  String get currentStreet {
    final step = currentStep;
    if (step == null) return '';
    final instr = step.instruction;
    final onIdx = instr.indexOf(' on ');
    if (onIdx != -1) return instr.substring(onIdx + 4);
    final ontoIdx = instr.indexOf(' onto ');
    if (ontoIdx != -1) return instr.substring(ontoIdx + 6);
    return instr;
  }

  double get dynamicEtaSeconds {
    if (_speedMs > AppConfig.navLowSpeedThreshold &&
        _totalRemainingDistance > 0) {
      return _totalRemainingDistance / _speedMs;
    }
    return _totalRemainingDuration;
  }

  DateTime get etaDateTime =>
      DateTime.now().add(Duration(seconds: dynamicEtaSeconds.ceil()));

  String get etaText {
    final minutes = (dynamicEtaSeconds / 60).ceil();
    if (minutes >= 60) {
      return '${minutes ~/ 60}h ${minutes % 60}m';
    }
    return '$minutes min';
  }

  String get etaTimeText {
    final arrival = etaDateTime;
    final h = arrival.hour;
    final m = arrival.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }

  String get distanceToNextText {
    if (_distanceToNextStep >= 1000) {
      return '${(_distanceToNextStep / 1000).toStringAsFixed(1)} km';
    }
    return '${_distanceToNextStep.toInt()} m';
  }

  void toggleVoice() {
    _voiceEnabled = !_voiceEnabled;
    if (!_voiceEnabled) VoiceService.stop();
    notifyListeners();
  }

  Future<void> startNavigation(RouteModel route) async {
    await RouteCache.cacheRoute(route);
    _route = route;
    _currentStepIndex = 0;
    _state = NavState.navigating;
    _announcedDistances.clear();
    _computeRemaining();
    notifyListeners();

    if (_voiceEnabled) {
      await VoiceService.speakNavStart(route.destination.name ?? 'destination');
    }

    _gpsSub = LocationService.getPositionStream(intervalMs: 2000).listen(
      _onPositionUpdate,
      onError: (_) {},
    );
  }

  void stopNavigation() {
    _gpsSub?.cancel();
    _gpsSub = null;
    _route = null;
    _currentStepIndex = 0;
    _state = NavState.idle;
    _announcedDistances.clear();
    VoiceService.stop();
    notifyListeners();
  }

  static bool _isInPhilippines(double lat, double lng) {
    return lat >= 4.5 && lat <= 21.5 && lng >= 116.0 && lng <= 127.0;
  }

  Position _adjustedPosition(Position pos) {
    if (_isInPhilippines(pos.latitude, pos.longitude)) return pos;
    if (_route != null && _route!.coordinates.isNotEmpty) {
      final start = _route!.coordinates.first;
      return Position(
        latitude: start[1],
        longitude: start[0],
        timestamp: pos.timestamp,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        altitudeAccuracy: pos.altitudeAccuracy,
        heading: pos.heading,
        headingAccuracy: pos.headingAccuracy,
        speed: 0,
        speedAccuracy: pos.speedAccuracy,
      );
    }
    return pos;
  }

  void _onPositionUpdate(Position raw) {
    final pos = _adjustedPosition(raw);
    _lastPosition = pos;
    _speedMs = pos.speed.isNaN ? 0 : pos.speed;

    if (_route == null || _state == NavState.arrived) return;

    final step = currentStep;
    if (step == null) {
      _arrive();
      return;
    }

    if (step.maneuverLat != null && step.maneuverLng != null) {
      _distanceToNextStep =
          _haversine(pos.latitude, pos.longitude, step.maneuverLat!, step.maneuverLng!);
    }

    _checkOffRoute(pos);

    if (_distanceToNextStep <= AppConfig.navStepAdvanceMeters) {
      _advanceStep();
    } else {
      _announceDistance();
    }

    _computeRemaining();
    notifyListeners();
  }

  void _advanceStep() {
    _announcedDistances.clear();
    _currentStepIndex++;

    if (_currentStepIndex >= _route!.steps.length) {
      _arrive();
      return;
    }

    _state = NavState.navigating;
    final step = currentStep;
    if (step != null && _voiceEnabled && _speedMs >= AppConfig.navLowSpeedThreshold) {
      VoiceService.speakNavInstruction(step.instruction);
    }
  }

  void _arrive() {
    _state = NavState.arrived;
    if (_voiceEnabled) {
      VoiceService.speakArrival(_route?.destination.name ?? 'destination');
    }
    _gpsSub?.cancel();
    _gpsSub = null;
    notifyListeners();
  }

  double get _dynamicAnnounceDistance {
    final kmh = _speedMs * 3.6;
    if (kmh > AppConfig.voiceTierHighwayKmh) return AppConfig.voiceTierHighwayMeters;
    if (kmh > AppConfig.voiceTierNormalKmh) return AppConfig.voiceTierNormalMeters;
    if (kmh > AppConfig.voiceTierSlowKmh) return AppConfig.voiceTierSlowMeters;
    return AppConfig.voiceTierCrawlMeters;
  }

  void _announceDistance() {
    if (!_voiceEnabled || _speedMs < AppConfig.navLowSpeedThreshold) return;

    final step = currentStep;
    if (step == null) return;

    final farDist = _dynamicAnnounceDistance;
    final nearDist = (farDist * 0.4).clamp(40.0, 200.0);

    final keyFar = '${_currentStepIndex}_far';
    final keyNear = '${_currentStepIndex}_near';

    if (_distanceToNextStep <= farDist &&
        _distanceToNextStep > nearDist &&
        !_announcedDistances.contains(keyFar)) {
      _announcedDistances.add(keyFar);
      VoiceService.speakNavStep(
          step.modifier, step.maneuverType, step.instruction, farDist.toInt());
    } else if (_distanceToNextStep <= nearDist &&
        _distanceToNextStep > AppConfig.navVoiceAnnounceNow &&
        !_announcedDistances.contains(keyNear)) {
      _announcedDistances.add(keyNear);
      VoiceService.speakNavStep(
          step.modifier, step.maneuverType, step.instruction, nearDist.toInt());
    }
  }

  void _checkOffRoute(Position pos) {
    if (_route == null) return;

    double minDist = double.infinity;
    for (final coord in _route!.coordinates) {
      final d = _haversine(pos.latitude, pos.longitude, coord[1], coord[0]);
      if (d < minDist) minDist = d;
    }

    if (minDist > AppConfig.navOffRouteMeters) {
      if (_state != NavState.offRoute) {
        _state = NavState.offRoute;
        if (_voiceEnabled) {
          VoiceService.speakOffRoute();
        }
      }
    } else if (_state == NavState.offRoute) {
      _state = NavState.navigating;
      if (_voiceEnabled) {
        VoiceService.speak('Back on route.');
      }
    }
  }

  void _computeRemaining() {
    if (_route == null) return;
    double dist = _distanceToNextStep;
    double dur = 0;
    for (int i = _currentStepIndex; i < _route!.steps.length; i++) {
      if (i > _currentStepIndex) {
        dist += _route!.steps[i].distance;
      }
      dur += _route!.steps[i].duration;
    }
    _totalRemainingDistance = dist;
    _totalRemainingDuration = dur;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
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
    _gpsSub?.cancel();
    super.dispose();
  }
}

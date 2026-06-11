import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../config/app_config.dart';

class BatterySaver extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isStationary = false;
  double _lastMagnitude = 0;
  DateTime _lastMovement = DateTime.now();

  bool get isStationary => _isStationary;

  int get recommendedGpsIntervalMs => _isStationary
      ? AppConfig.stationaryGpsIntervalMs
      : AppConfig.movingGpsIntervalMs;

  void start() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 500),
    ).listen(_onAccelData);
  }

  void _onAccelData(AccelerometerEvent event) {
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final delta = (magnitude - _lastMagnitude).abs();
    _lastMagnitude = magnitude;

    if (delta > AppConfig.stationaryThreshold) {
      _lastMovement = DateTime.now();
      if (_isStationary) {
        _isStationary = false;
        notifyListeners();
      }
    } else {
      final stoppedFor = DateTime.now().difference(_lastMovement);
      if (!_isStationary && stoppedFor.inSeconds > 5) {
        _isStationary = true;
        notifyListeners();
        debugPrint('BatterySaver: Rider stationary — throttling GPS');
      }
    }
  }

  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

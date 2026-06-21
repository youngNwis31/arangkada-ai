import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../core/database/local_database.dart';
import 'ai/voice_service.dart';
import 'offline_nav_engine.dart';

class SpeedMonitor extends ChangeNotifier {
  final OfflineNavEngine _navEngine;
  double _speedLimitKmh = AppConfig.defaultSpeedLimitKmh;
  DateTime? _lastWarning;

  SpeedMonitor(this._navEngine) {
    _navEngine.addListener(_onNavUpdate);
    _loadSpeedLimit();
  }

  double get currentSpeedKmh => _navEngine.speedMs * 3.6;
  double get speedLimitKmh => _speedLimitKmh;
  bool get isOverLimit => currentSpeedKmh > _speedLimitKmh;

  Future<void> _loadSpeedLimit() async {
    final raw = await LocalDatabase.getRiderSetting('speed_limit_kmh');
    if (raw != null) {
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed >= 30 && parsed <= 120) {
        _speedLimitKmh = parsed;
        notifyListeners();
      }
    }
  }

  Future<void> setSpeedLimit(double kmh) async {
    _speedLimitKmh = kmh.clamp(30.0, 120.0);
    await LocalDatabase.setRiderSetting(
      'speed_limit_kmh',
      _speedLimitKmh.toString(),
    );
    notifyListeners();
  }

  void _onNavUpdate() {
    notifyListeners();

    if (!_navEngine.isNavigating) return;
    if (!isOverLimit) return;

    final now = DateTime.now();
    if (_lastWarning != null &&
        now.difference(_lastWarning!).inSeconds <
            AppConfig.speedWarningCooldownSeconds) {
      return;
    }

    _lastWarning = now;
    VoiceService.speak(
      'Speed warning! ${currentSpeedKmh.toInt()} km/h. '
      'Limit is ${_speedLimitKmh.toInt()} km/h. Bagalan mo, rider!',
    );
    debugPrint(
      'SpeedMonitor: Over limit ${currentSpeedKmh.toInt()}/${_speedLimitKmh.toInt()} km/h',
    );
  }

  @override
  void dispose() {
    _navEngine.removeListener(_onNavUpdate);
    super.dispose();
  }
}

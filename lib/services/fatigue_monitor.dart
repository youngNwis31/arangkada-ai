import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/database/local_database.dart';
import 'ai/voice_service.dart';
import 'navigation_provider.dart';

class FatigueMonitor extends ChangeNotifier {
  final NavigationProvider _nav;
  Timer? _timer;
  DateTime? _rideStart;
  bool _wasNavigating = false;
  final Set<int> _alertedHours = {};

  FatigueMonitor(this._nav) {
    _nav.addListener(_onNavChange);
    _restoreState();
  }

  Duration get continuousRideTime {
    if (_rideStart == null) return Duration.zero;
    return DateTime.now().difference(_rideStart!);
  }

  bool get isRiding => _rideStart != null && _nav.isNavigating;
  bool get shouldRest => continuousRideTime.inHours >= 2;
  bool get mustRest => continuousRideTime.inHours >= 4;

  String get rideTimeText {
    final d = continuousRideTime;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Future<void> _restoreState() async {
    final raw = await LocalDatabase.getRiderSetting('fatigue_ride_start');
    if (raw != null) {
      final ts = int.tryParse(raw);
      if (ts != null) {
        _rideStart = DateTime.fromMillisecondsSinceEpoch(ts);
        if (_nav.isNavigating) {
          _startTimer();
        }
      }
    }
  }

  void _onNavChange() {
    final navigating = _nav.isNavigating;
    if (navigating && !_wasNavigating) {
      _startRide();
    } else if (!navigating && _wasNavigating) {
      _stopTimer();
    }
    _wasNavigating = navigating;
  }

  void _startRide() {
    _rideStart ??= DateTime.now();
    _persistStart();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAlerts();
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _checkAlerts() {
    final hours = continuousRideTime.inHours;
    if (hours >= 2 && !_alertedHours.contains(2)) {
      _alertedHours.add(2);
      VoiceService.speak(
        'Rider, 2 hours ka na sa daan. Mag-pahinga ka muna.',
      );
    }
    if (hours >= 3 && !_alertedHours.contains(3)) {
      _alertedHours.add(3);
      VoiceService.speak(
        '3 hours na! Please mag-rest, rider. Para sa safety mo.',
      );
    }
    if (hours >= 4 && !_alertedHours.contains(4)) {
      _alertedHours.add(4);
      VoiceService.speak(
        'Warning! 4 hours ka na. Huminto ka na, rider!',
      );
    }
  }

  void markRest() {
    _rideStart = null;
    _alertedHours.clear();
    _stopTimer();
    LocalDatabase.setRiderSetting('fatigue_ride_start', '');
    notifyListeners();
    VoiceService.speak('Rest timer reset. Pahinga muna, rider!');
    debugPrint('FatigueMonitor: Rest marked, timer reset');
  }

  Future<void> _persistStart() async {
    if (_rideStart != null) {
      await LocalDatabase.setRiderSetting(
        'fatigue_ride_start',
        _rideStart!.millisecondsSinceEpoch.toString(),
      );
    }
  }

  @override
  void dispose() {
    _nav.removeListener(_onNavChange);
    _stopTimer();
    super.dispose();
  }
}

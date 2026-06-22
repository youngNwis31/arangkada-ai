import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../config/app_config.dart';
import '../core/database/local_database.dart';
import 'ai/voice_service.dart';

enum CrashState { idle, detected, countdown, sosTriggered }

class CrashDetector extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _countdownTimer;
  DateTime? _lastTrigger;

  CrashState _state = CrashState.idle;
  int _secondsRemaining = AppConfig.crashCountdownSeconds;

  final Queue<_AccelSample> _window = Queue();

  CrashState get state => _state;
  int get secondsRemaining => _secondsRemaining;
  bool get isActive => _state != CrashState.idle;

  void start() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(
        milliseconds: AppConfig.crashSamplingMs,
      ),
    ).listen(_onAccelData);
  }

  void _onAccelData(AccelerometerEvent event) {
    if (_state == CrashState.countdown || _state == CrashState.sosTriggered) {
      return;
    }

    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final now = DateTime.now();

    _window.addLast(_AccelSample(magnitude, now));
    while (_window.length > AppConfig.crashWindowSamples) {
      _window.removeFirst();
    }

    if (_window.length < 3) return;

    if (_lastTrigger != null &&
        now.difference(_lastTrigger!).inSeconds <
            AppConfig.crashCooldownSeconds) {
      return;
    }

    // Crash = spike >4G followed by drop within 200ms
    final samples = _window.toList();
    for (int i = 0; i < samples.length - 1; i++) {
      if (samples[i].magnitude > AppConfig.crashThresholdMs2) {
        final spike = samples[i];
        for (int j = i + 1; j < samples.length; j++) {
          final elapsed =
              samples[j].time.difference(spike.time).inMilliseconds;
          if (elapsed > AppConfig.crashDropWindowMs) break;
          if (samples[j].magnitude <
              AppConfig.crashThresholdMs2 * AppConfig.crashDropRatio) {
            _triggerCrashDetected();
            return;
          }
        }
      }
    }
  }

  void _triggerCrashDetected() {
    _lastTrigger = DateTime.now();
    _state = CrashState.detected;
    _window.clear();
    notifyListeners();

    VoiceService.speak(
      'Crash detected! Are you OK? Tap I\'m OK or SOS will send in '
      '${AppConfig.crashCountdownSeconds} seconds.',
    );

    _state = CrashState.countdown;
    _secondsRemaining = AppConfig.crashCountdownSeconds;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _triggerSos();
      } else {
        notifyListeners();
      }
    });
  }

  void triggerSos() => _triggerSos();

  void dismiss() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _state = CrashState.idle;
    _secondsRemaining = AppConfig.crashCountdownSeconds;
    notifyListeners();
    VoiceService.speak('Good to hear you\'re OK, rider. Ride safe!');
    debugPrint('CrashDetector: Dismissed by rider');
  }

  Future<void> _triggerSos() async {
    _state = CrashState.sosTriggered;
    notifyListeners();

    final msg = await _buildSosMessage();
    await Clipboard.setData(ClipboardData(text: msg));
    await VoiceService.speak(
      'SOS message copied to clipboard! Paste and send to your emergency contacts.',
    );

    await Future.delayed(const Duration(seconds: 3));
    _state = CrashState.idle;
    _secondsRemaining = AppConfig.crashCountdownSeconds;
    notifyListeners();
    debugPrint('CrashDetector: SOS triggered, message copied');
  }

  Future<String> _buildSosMessage() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String contactsInfo = '';
    try {
      final raw =
          await LocalDatabase.getRiderSetting('emergency_contacts_json');
      if (raw != null && raw.isNotEmpty) {
        final contacts = jsonDecode(raw) as List<dynamic>;
        if (contacts.isNotEmpty) {
          contactsInfo = ' Emergency contacts: ${contacts.map((c) => '${c['name']} (${c['phone']})').join(', ')}.';
        }
      }
    } catch (_) {}

    return 'EMERGENCY! Arangkada AI CRASH DETECTED. '
        'Rider may need help. Time: $dateStr.$contactsInfo '
        'Please call emergency services if rider is unresponsive.';
  }

  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

class _AccelSample {
  final double magnitude;
  final DateTime time;
  _AccelSample(this.magnitude, this.time);
}

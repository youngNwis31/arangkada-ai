import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../core/database/local_database.dart';
import '../services/ai/ai_assistant.dart';
import '../services/ai/voice_service.dart';
import '../services/crash_detector.dart';
import '../services/fatigue_monitor.dart';
import '../services/navigation_provider.dart';
import '../services/night_mode_provider.dart';
import '../services/ride_logger.dart';
import '../services/speed_monitor.dart';
import '../services/hazard_service.dart';
import '../models/hazard_report.dart';
import '../services/mapbox_service.dart';

enum VoiceCommandState { idle, listening, processing, error }

class VoiceCommandService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  VoiceCommandState _state = VoiceCommandState.idle;
  String _transcript = '';
  String _resultMessage = '';
  bool _isAvailable = false;

  bool _autoListenEnabled = false;
  Timer? _autoListenTimer;
  Timer? _statusTimer;
  int _statusIntervalMinutes = 15;
  bool _isAutoListenWindow = false;

  NavigationProvider? _nav;
  RideLogger? _rideLogger;
  AiAssistant? _aiAssistant;
  SpeedMonitor? _speedMonitor;
  FatigueMonitor? _fatigueMonitor;
  CrashDetector? _crashDetector;
  NightModeProvider? _nightMode;

  VoiceCommandState get state => _state;
  String get transcript => _transcript;
  String get resultMessage => _resultMessage;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == VoiceCommandState.listening;
  bool get autoListenEnabled => _autoListenEnabled;
  bool get isAutoListenWindow => _isAutoListenWindow;
  int get statusIntervalMinutes => _statusIntervalMinutes;

  Future<void> init() async {
    _isAvailable = await _speech.initialize(
      onError: (error) {
        _state = VoiceCommandState.error;
        _resultMessage = 'Voice error: ${error.errorMsg}';
        notifyListeners();
        Future.delayed(const Duration(seconds: 2), () {
          if (_state == VoiceCommandState.error) {
            _state = VoiceCommandState.idle;
            notifyListeners();
          }
        });
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_state == VoiceCommandState.listening && _transcript.isNotEmpty) {
            _processTranscript(_transcript);
          } else if (_state == VoiceCommandState.listening) {
            _state = VoiceCommandState.idle;
            notifyListeners();
          }
        }
      },
    );
    await loadAutoListenSettings();
    notifyListeners();
  }

  void setDependencies({
    NavigationProvider? nav,
    RideLogger? rideLogger,
    AiAssistant? aiAssistant,
  }) {
    _nav = nav;
    _rideLogger = rideLogger;
    _aiAssistant = aiAssistant;
  }

  void setSafetyDependencies({
    required SpeedMonitor speedMonitor,
    required FatigueMonitor fatigueMonitor,
    required CrashDetector crashDetector,
    required NightModeProvider nightMode,
  }) {
    _speedMonitor = speedMonitor;
    _fatigueMonitor = fatigueMonitor;
    _crashDetector = crashDetector;
    _nightMode = nightMode;
  }

  Future<void> startListening() async {
    if (!_isAvailable) {
      _resultMessage = 'Voice recognition not available';
      _state = VoiceCommandState.error;
      notifyListeners();
      return;
    }

    _transcript = '';
    _resultMessage = '';
    _state = VoiceCommandState.listening;
    notifyListeners();

    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en-PH',
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    if (_transcript.isNotEmpty) {
      _processTranscript(_transcript);
    } else {
      _state = VoiceCommandState.idle;
      notifyListeners();
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    _transcript = result.recognizedWords;
    notifyListeners();

    if (result.finalResult && _transcript.isNotEmpty) {
      _processTranscript(_transcript);
    }
  }

  Future<void> _processTranscript(String text) async {
    _state = VoiceCommandState.processing;
    notifyListeners();

    final q = text.toLowerCase().trim();

    try {
      if (_matchSafety(q)) return;
      if (_matchNavigation(q)) return;
      if (_matchRideLog(q)) return;
      if (_matchHazard(q)) return;
      if (_matchEarnings(q)) return;
      if (_matchAiPassthrough(q, text)) return;

      // Fallback: treat as AI question
      _handleAiQuestion(text);
    } catch (e) {
      _resultMessage = 'Error processing command';
      _state = VoiceCommandState.error;
      notifyListeners();
      await VoiceService.speak('Sorry, may error. Try again, rider.');
      Future.delayed(const Duration(seconds: 2), () {
        _state = VoiceCommandState.idle;
        notifyListeners();
      });
    }
  }

  bool _matchSafety(String q) {
    // Reroute
    if (q == 'reroute' || q.contains('ibang daan') || q.contains('ibang route')) {
      _handleReroute();
      return true;
    }

    // Speed query
    if (q.contains('speed ko') || q.contains('bilis ko') ||
        q == 'speed' || q.contains('how fast')) {
      _handleSpeedQuery();
      return true;
    }

    // ETA query
    if (q.contains('gaano kalayo') || q.contains('kalayo pa') ||
        q == 'eta' || q.contains('how far') || q.contains('malayo pa')) {
      _handleEtaQuery();
      return true;
    }

    // Night mode
    if (q.contains('night mode') || q.contains('gabi mode') ||
        q.contains('night') && q.contains('mode')) {
      _handleNightMode();
      return true;
    }

    // Rest / fatigue reset
    if (q == 'pahinga' || q == 'rest' || q.contains('take a break') ||
        q.contains('mag pahinga') || q.contains('magpahinga')) {
      _handleRest();
      return true;
    }

    // Dismiss crash alert
    if (q.contains("i'm ok") || q.contains('im ok') ||
        q.contains('ok lang') || q.contains('okay lang') ||
        q.contains("i am ok") || q.contains('ok ako')) {
      _handleDismissCrash();
      return true;
    }

    // SOS / Help
    if (q == 'help' || q == 'tulong' || q == 'sos' ||
        q.contains('emergency') || q.contains('saklolo')) {
      _handleSos();
      return true;
    }

    // Status summary
    if (q == 'status' || q == 'sitrep' || q.contains('status ko') ||
        q.contains('anong nangyayari')) {
      _handleStatus();
      return true;
    }

    return false;
  }

  Future<void> _handleReroute() async {
    if (_nav == null || !_nav!.isNavigating) {
      _respond('Not navigating right now');
      await VoiceService.speak('Hindi ka nag-navigate, rider.');
      return;
    }
    _resultMessage = 'Finding alternative route...';
    notifyListeners();
    await VoiceService.speak('Hanap ng ibang daan...');

    try {
      final dest = _nav!.destination;
      final origin = _nav!.origin;
      if (dest == null || origin == null) {
        _respond('No route to reroute');
        return;
      }
      _nav!.stopNavigation();
      await _nav!.fetchRoutes();
      if (_nav!.routes.length > 1) {
        _nav!.selectRoute(1);
      }
      await _nav!.startNavigation();
      _respond('New route found! Tara na.');
      await VoiceService.speak('New route! Tara na, rider.');
    } catch (_) {
      _respond('Reroute failed');
      await VoiceService.speak('Sorry, walang ibang daan.');
    }
  }

  void _handleSpeedQuery() {
    final kmh = _speedMonitor?.currentSpeedKmh.toInt() ?? 0;
    final limit = _speedMonitor?.speedLimitKmh.toInt() ?? 60;
    final text = '$kmh km/h. Limit is $limit.';
    _respond(text);
    VoiceService.speak('$kmh kilometers per hour. Limit is $limit.');
  }

  void _handleEtaQuery() {
    final engine = _nav?.navEngine;
    if (engine == null || !engine.isNavigating) {
      _respond('Not navigating');
      VoiceService.speak('Hindi ka nag-navigate, rider.');
      return;
    }
    final dist = engine.totalRemainingDistance;
    final distText = dist >= 1000
        ? '${(dist / 1000).toStringAsFixed(1)} km'
        : '${dist.toInt()} meters';
    final eta = engine.etaText;
    final arrival = engine.etaTimeText;
    _respond('$distText left. ETA $eta ($arrival)');
    VoiceService.speak('$distText pa. $eta, arrival $arrival.');
  }

  void _handleNightMode() {
    if (_nightMode == null) {
      _respond('Night mode not available');
      return;
    }
    _nightMode!.toggle();
    final on = _nightMode!.isNightMode;
    _respond('Night mode ${on ? "ON" : "OFF"}');
    VoiceService.speak('Night mode ${on ? "on" : "off"}, rider.');
  }

  void _handleRest() {
    _fatigueMonitor?.markRest();
    _respond('Rest timer reset');
    VoiceService.speak('Rest timer reset. Pahinga muna, rider!');
  }

  void _handleDismissCrash() {
    _crashDetector?.dismiss();
    _respond('Crash alert dismissed');
    VoiceService.speak('Ok, glad you are ok, rider!');
  }

  void _handleSos() {
    _crashDetector?.triggerSos();
    _respond('SOS triggered!');
  }

  void _handleStatus() {
    final parts = <String>[];

    if (_nav?.isNavigating == true) {
      final engine = _nav!.navEngine;
      final dist = engine.totalRemainingDistance;
      final distText = dist >= 1000
          ? '${(dist / 1000).toStringAsFixed(1)} km'
          : '${dist.toInt()} m';
      parts.add('$distText left, ETA ${engine.etaText}');
    } else {
      parts.add('Not navigating');
    }

    final kmh = _speedMonitor?.currentSpeedKmh.toInt() ?? 0;
    parts.add('Speed: $kmh km/h');

    if (_fatigueMonitor?.isRiding == true) {
      parts.add('Riding: ${_fatigueMonitor!.rideTimeText}');
    }

    final summary = parts.join('. ');
    _respond(summary);
    VoiceService.speak(summary);
  }

  void _respond(String message) {
    _resultMessage = message;
    _state = VoiceCommandState.idle;
    notifyListeners();
  }

  bool _matchNavigation(String q) {
    final navPatterns = [
      RegExp(r'^(?:navigate|go|directions?|take me|drive)\s+to\s+(.+)$', caseSensitive: false),
      RegExp(r'^(?:papunta|punta|daan)\s+(?:sa|ng)\s+(.+)$', caseSensitive: false),
    ];

    for (final pattern in navPatterns) {
      final match = pattern.firstMatch(q);
      if (match != null) {
        final place = match.group(1)!.trim();
        _handleNavigation(place);
        return true;
      }
    }
    return false;
  }

  bool _matchRideLog(String q) {
    final ridePatterns = [
      RegExp(r'^(?:log|book|end)\s+(?:ride\s+)?(\w+)\s+(\d+)', caseSensitive: false),
    ];

    for (final pattern in ridePatterns) {
      final match = pattern.firstMatch(q);
      if (match != null) {
        final platform = match.group(1)!.trim();
        final amount = double.tryParse(match.group(2)!) ?? 0;
        if (amount > 0) {
          _handleRideLog(platform, amount);
          return true;
        }
      }
    }
    return false;
  }

  bool _matchHazard(String q) {
    final hazardMap = {
      'pothole': HazardType.pothole,
      'lubak': HazardType.pothole,
      'flood': HazardType.flooding,
      'baha': HazardType.flooding,
      'accident': HazardType.accident,
      'aksidente': HazardType.accident,
      'checkpoint': HazardType.checkpoint,
      'road closure': HazardType.roadClosure,
      'sarado': HazardType.roadClosure,
      'construction': HazardType.construction,
      'gawa': HazardType.construction,
    };

    if (q.startsWith('report ') || q.startsWith('may ') || q.startsWith('meron ')) {
      for (final entry in hazardMap.entries) {
        if (q.contains(entry.key)) {
          _handleHazardReport(entry.value);
          return true;
        }
      }
    }

    for (final entry in hazardMap.entries) {
      if (q == entry.key) {
        _handleHazardReport(entry.value);
        return true;
      }
    }

    return false;
  }

  bool _matchEarnings(String q) {
    final earningsPatterns = [
      'earnings today', 'earnings', 'kita ko', 'kita today',
      'how much today', 'magkano kita', 'income today',
    ];

    for (final pattern in earningsPatterns) {
      if (q.contains(pattern)) {
        _handleEarningsQuery();
        return true;
      }
    }
    return false;
  }

  bool _matchAiPassthrough(String q, String original) {
    final aiPrefixes = ['hey arangkada', 'ask arangkada', 'arangkada'];
    for (final prefix in aiPrefixes) {
      if (q.startsWith(prefix)) {
        final question = original.substring(prefix.length).trim();
        if (question.isNotEmpty) {
          _handleAiQuestion(question);
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _handleNavigation(String place) async {
    _resultMessage = 'Searching for $place...';
    notifyListeners();
    await VoiceService.speak('Searching for $place');

    try {
      final results = await MapboxService.searchPlaces(place);
      if (results.isNotEmpty) {
        final dest = results.first;
        _nav?.setDestination(dest);
        _resultMessage = 'Navigating to ${dest.name}';
        await VoiceService.speak('Navigating to ${dest.name}');
      } else {
        _resultMessage = 'Place not found: $place';
        await VoiceService.speak("Sorry, I couldn't find $place");
      }
    } catch (_) {
      _resultMessage = 'Search failed — try again';
      await VoiceService.speak('Search failed. Try again, rider.');
    }

    _state = VoiceCommandState.idle;
    notifyListeners();
  }

  void _handleRideLog(String platform, double amount) {
    final normalizedPlatform = _normalizePlatform(platform);
    _rideLogger?.logQuickRide(platform: normalizedPlatform, earning: amount);
    _resultMessage = 'Logged ₱${amount.toStringAsFixed(0)} on $normalizedPlatform';
    _state = VoiceCommandState.idle;
    notifyListeners();
    VoiceService.speak(
        'Ride logged! ${amount.toStringAsFixed(0)} pesos on $normalizedPlatform');
  }

  String _normalizePlatform(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('grab')) return 'Grab';
    if (lower.contains('food') || lower.contains('panda')) return 'FoodPanda';
    if (lower.contains('lala') || lower.contains('move')) return 'Lalamove';
    if (lower.contains('angkas')) return 'Angkas';
    if (lower.contains('joy')) return 'JoyRide';
    if (lower.contains('moveit')) return 'MoveIt';
    return input[0].toUpperCase() + input.substring(1);
  }

  void _handleHazardReport(HazardType type) {
    final pos = _nav?.currentLocation;
    if (pos != null) {
      HazardService.reportHazard(
        type: type,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _resultMessage = '${type.english} reported at current location';
      VoiceService.speak('${type.english} reported! Ingat, rider.');
    } else {
      _resultMessage = 'Cannot report — no GPS location';
      VoiceService.speak('No GPS location available. Try again.');
    }
    _state = VoiceCommandState.idle;
    notifyListeners();
  }

  void _handleEarningsQuery() {
    final earnings = _rideLogger?.todayEarnings ?? 0;
    final rides = _rideLogger?.todayRideCount ?? 0;
    final text = rides > 0
        ? 'Today you earned ${earnings.toStringAsFixed(0)} pesos from $rides ${rides == 1 ? "ride" : "rides"}'
        : 'No rides logged today yet';
    _resultMessage = text;
    _state = VoiceCommandState.idle;
    notifyListeners();
    VoiceService.speak(text);
  }

  void _handleAiQuestion(String question) {
    _aiAssistant?.sendMessage(question);
    _resultMessage = 'Asked AI: $question';
    _state = VoiceCommandState.idle;
    notifyListeners();
    VoiceService.speak('Let me think about that...');
  }

  Future<void> toggleAutoListen() async {
    _autoListenEnabled = !_autoListenEnabled;
    await LocalDatabase.setRiderSetting(
        'auto_listen_enabled', _autoListenEnabled.toString());
    if (_autoListenEnabled) {
      _startAutoListen();
    } else {
      _stopAutoListen();
    }
    notifyListeners();
    debugPrint('AutoListen: ${_autoListenEnabled ? "ON" : "OFF"}');
  }

  void setAutoListen(bool value) {
    if (_autoListenEnabled == value) return;
    _autoListenEnabled = value;
    LocalDatabase.setRiderSetting(
        'auto_listen_enabled', _autoListenEnabled.toString());
    if (value) {
      _startAutoListen();
    } else {
      _stopAutoListen();
    }
    notifyListeners();
  }

  Future<void> setStatusInterval(int minutes) async {
    _statusIntervalMinutes = minutes;
    await LocalDatabase.setRiderSetting(
        'status_update_interval_minutes', minutes.toString());
    if (_autoListenEnabled) {
      _restartStatusTimer();
    }
    notifyListeners();
  }

  Future<void> loadAutoListenSettings() async {
    final enabled =
        await LocalDatabase.getRiderSetting('auto_listen_enabled');
    if (enabled == 'true') {
      _autoListenEnabled = true;
    }
    final interval =
        await LocalDatabase.getRiderSetting('status_update_interval_minutes');
    if (interval != null) {
      _statusIntervalMinutes = int.tryParse(interval) ?? 15;
    }
  }

  void _startAutoListen() {
    _autoListenTimer?.cancel();
    _autoListenTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _autoListenTick());
    _restartStatusTimer();
  }

  void _stopAutoListen() {
    _autoListenTimer?.cancel();
    _autoListenTimer = null;
    _statusTimer?.cancel();
    _statusTimer = null;
    _isAutoListenWindow = false;
    notifyListeners();
  }

  void _restartStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
        Duration(minutes: _statusIntervalMinutes), (_) => _speakStatus());
  }

  void _autoListenTick() {
    if (_nav?.isNavigating != true) return;
    if (_state != VoiceCommandState.idle) return;

    _isAutoListenWindow = true;
    notifyListeners();
    startListening();

    Future.delayed(const Duration(seconds: 5), () {
      if (_state == VoiceCommandState.listening && _transcript.isEmpty) {
        _speech.stop();
        _state = VoiceCommandState.idle;
        _isAutoListenWindow = false;
        notifyListeners();
      } else {
        _isAutoListenWindow = false;
        notifyListeners();
      }
    });
  }

  void _speakStatus() {
    if (_nav?.isNavigating != true) return;

    final engine = _nav!.navEngine;
    final etaMin = (engine.dynamicEtaSeconds / 60).ceil();
    final distKm = (engine.totalRemainingDistance / 1000).toStringAsFixed(1);
    final arrival = engine.etaTimeText;

    VoiceService.speak(
        '$etaMin minutes na, $distKm km pa. Arrival $arrival.');
  }

  @override
  void dispose() {
    _speech.cancel();
    _autoListenTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }
}

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
import '../application/voice/commands/voice_command_handler.dart';
import '../application/voice/commands/safety_commands.dart';
import '../application/voice/commands/navigation_commands.dart';
import '../application/voice/commands/ride_commands.dart';
import '../application/voice/commands/hazard_commands.dart';

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

  // ── Command handlers (extracted from god class) ──
  final SafetyCommandHandler _safetyHandler = SafetyCommandHandler();
  final NavigationCommandHandler _navHandler = NavigationCommandHandler();
  final RideCommandHandler _rideHandler = RideCommandHandler();
  final HazardCommandHandler _hazardHandler = HazardCommandHandler();

  late final List<VoiceCommandHandler> _handlers;

  NavigationProvider? _nav;
  AiAssistant? _aiAssistant;

  VoiceCommandState get state => _state;
  String get transcript => _transcript;
  String get resultMessage => _resultMessage;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == VoiceCommandState.listening;
  bool get autoListenEnabled => _autoListenEnabled;
  bool get isAutoListenWindow => _isAutoListenWindow;
  int get statusIntervalMinutes => _statusIntervalMinutes;

  VoiceCommandService() {
    _handlers = [_safetyHandler, _navHandler, _rideHandler, _hazardHandler];
  }

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
    _aiAssistant = aiAssistant;

    _safetyHandler.nav = nav;
    _navHandler.nav = nav;
    _hazardHandler.nav = nav;
    _rideHandler.rideLogger = rideLogger;
  }

  void setSafetyDependencies({
    required SpeedMonitor speedMonitor,
    required FatigueMonitor fatigueMonitor,
    required CrashDetector crashDetector,
    required NightModeProvider nightMode,
  }) {
    _safetyHandler.speedMonitor = speedMonitor;
    _safetyHandler.fatigueMonitor = fatigueMonitor;
    _safetyHandler.crashDetector = crashDetector;
    _safetyHandler.nightMode = nightMode;
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
      // Run through handler chain — first match wins
      for (final handler in _handlers) {
        final result = await handler.tryHandle(q, text);
        if (result.matched) {
          _resultMessage = result.message;
          _state = VoiceCommandState.idle;
          notifyListeners();
          return;
        }
      }

      // AI passthrough check
      final aiPrefixes = ['hey arangkada', 'ask arangkada', 'arangkada'];
      for (final prefix in aiPrefixes) {
        if (q.startsWith(prefix)) {
          final question = text.substring(prefix.length).trim();
          if (question.isNotEmpty) {
            _handleAiQuestion(question);
            return;
          }
        }
      }

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

  void _handleAiQuestion(String question) {
    _aiAssistant?.sendMessage(question);
    _resultMessage = 'Asked AI: $question';
    _state = VoiceCommandState.idle;
    notifyListeners();
    VoiceService.speak('Let me think about that...');
  }

  // ── Auto-Listen Mode ──

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

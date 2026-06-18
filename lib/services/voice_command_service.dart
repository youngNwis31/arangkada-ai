import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../services/ai/ai_assistant.dart';
import '../services/ai/voice_service.dart';
import '../services/navigation_provider.dart';
import '../services/ride_logger.dart';
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

  NavigationProvider? _nav;
  RideLogger? _rideLogger;
  AiAssistant? _aiAssistant;

  VoiceCommandState get state => _state;
  String get transcript => _transcript;
  String get resultMessage => _resultMessage;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == VoiceCommandState.listening;

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

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}

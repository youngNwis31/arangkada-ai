import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await _tts.setLanguage('en-PH');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  static Future<void> speak(String text) async {
    await init();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  static Future<void> speakDirection(String instruction) async {
    await speak(instruction);
  }

  static Future<void> speakHazardAlert(String hazardType) async {
    await speak('Warning! $hazardType reported ahead. Ingat, rider!');
  }

  static Future<void> speakNavStart(String destination) async {
    await speak('Tara! Navigating to $destination.');
  }

  static Future<void> speakNavInstruction(String instruction) async {
    await speak(instruction);
  }

  static Future<void> speakNavDistance(String instruction, int meters) async {
    await speak('In $meters meters, $instruction');
  }

  static Future<void> speakArrival(String destination) async {
    await speak('Nakarating ka na! You have arrived at $destination.');
  }

  static Future<void> speakOffRoute() async {
    await speak('Naliligaw ka, rider. Recalculating. Go back to the route.');
  }

  static Future<void> speakHazardNearby(String hazardTagalog, int meters) async {
    await speak('Warning! $hazardTagalog reported $meters meters ahead. Ingat!');
  }

  static Future<void> speakCommandConfirmation(String action) async {
    await speak(action);
  }

  static Future<void> speakEarningsSummary(double amount, int rides) async {
    await speak('Today you earned ${amount.toStringAsFixed(0)} pesos from $rides ${rides == 1 ? "ride" : "rides"}');
  }

  static Future<void> speakCommandError(String reason) async {
    await speak('Sorry, $reason. Try again, rider.');
  }

  static Future<void> speakFloodWarning(String severity, int meters) async {
    await speak('Warning! $severity reported $meters meters ahead. Find alternate route!');
  }

  static Future<void> speakWeatherAlert(String condition) async {
    await speak('Weather alert: $condition. Ingat sa biyahe!');
  }
}

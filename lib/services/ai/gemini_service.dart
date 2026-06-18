import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/offline/connectivity_monitor.dart';
import 'ai_context.dart';

class GeminiService {
  final ConnectivityMonitor connectivity;
  String? _apiKey;
  int _todayRequestCount = 0;
  int _minuteRequestCount = 0;
  DateTime _lastMinuteReset = DateTime.now();
  DateTime _lastDayReset = DateTime.now();

  GeminiService({required this.connectivity});

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  void setApiKey(String key) {
    _apiKey = key.trim();
  }

  bool get isAvailable {
    if (!connectivity.isOnline) return false;
    if (!hasApiKey) return false;
    _resetCountersIfNeeded();
    if (_minuteRequestCount >= AppConfig.geminiMaxRpm) return false;
    if (_todayRequestCount >= AppConfig.geminiMaxRpd) return false;
    return true;
  }

  String get statusText {
    if (!hasApiKey) return 'No API Key';
    if (!connectivity.isOnline) return 'Offline';
    _resetCountersIfNeeded();
    return 'Connected (${_todayRequestCount}/${AppConfig.geminiMaxRpd} today)';
  }

  void _resetCountersIfNeeded() {
    final now = DateTime.now();
    if (now.difference(_lastMinuteReset).inSeconds >= 60) {
      _minuteRequestCount = 0;
      _lastMinuteReset = now;
    }
    if (now.day != _lastDayReset.day || now.month != _lastDayReset.month) {
      _todayRequestCount = 0;
      _lastDayReset = now;
    }
  }

  Future<String> generateResponse(
    String message, {
    Map<String, String>? context,
    List<Map<String, String>>? history,
  }) async {
    if (!isAvailable) {
      throw Exception('Gemini not available');
    }

    _minuteRequestCount++;
    _todayRequestCount++;

    final systemPrompt = _buildSystemPrompt(context);
    final contents = <Map<String, dynamic>>[];

    // Add conversation history
    if (history != null) {
      for (final msg in history.take(10)) {
        contents.add({
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [{'text': msg['text'] ?? ''}],
        });
      }
    }

    // Add current message
    contents.add({
      'role': 'user',
      'parts': [{'text': message}],
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${AppConfig.geminiModel}:generateContent?key=$_apiKey',
    );

    final body = jsonEncode({
      'contents': contents,
      'systemInstruction': {
        'parts': [{'text': systemPrompt}],
      },
      'generationConfig': {
        'maxOutputTokens': 512,
        'temperature': 0.7,
      },
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }

    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Empty Gemini response');
    }

    return parts[0]['text'] as String? ?? '';
  }

  String _buildSystemPrompt(Map<String, String>? context) {
    final buf = StringBuffer();
    buf.writeln('You are Arangkada AI, a helpful Filipino motorcycle rider assistant app.');
    buf.writeln('You help riders in the Philippines with navigation, traffic rules, earnings optimization, motorcycle maintenance, and safety.');
    buf.writeln('Respond concisely (2-5 sentences). You understand Taglish (Tagalog-English mix).');
    buf.writeln('Always prioritize rider safety. Use Philippine-specific context (₱ currency, PH traffic laws, local landmarks).');

    if (context != null && context.isNotEmpty) {
      buf.writeln('\nCurrent rider context:');
      for (final entry in context.entries) {
        if (entry.value.isNotEmpty && !entry.value.contains('{')) {
          buf.writeln('- ${entry.key}: ${entry.value}');
        }
      }
    }

    return buf.toString();
  }
}

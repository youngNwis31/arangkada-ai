import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ride_logger.dart';
import '../../core/offline/connectivity_monitor.dart';
import 'ai_router.dart';
import 'gemini_service.dart';
import 'knowledge_base.dart';
import 'ai_context.dart';
import 'llm_service.dart';

enum ResponseSource { knowledgeBase, ruleBased, localLlm, gemini }

class AiAssistant extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  bool _isStreaming = false;
  RideLogger? _rideLogger;
  ConnectivityMonitor? _connectivity;
  LlmService? _llmService;
  GeminiService? _geminiService;
  AiRouter? _router;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;
  bool get isStreaming => _isStreaming;

  void updateDependencies({
    required RideLogger rideLogger,
    required ConnectivityMonitor connectivity,
  }) {
    _rideLogger = rideLogger;
    _connectivity = connectivity;
    _rebuildRouter();
  }

  void setLlmService(LlmService service) {
    _llmService = service;
    _rebuildRouter();
  }

  void setGeminiService(GeminiService service) {
    _geminiService = service;
    _rebuildRouter();
  }

  void _rebuildRouter() {
    if (_rideLogger != null &&
        _connectivity != null &&
        _llmService != null &&
        _geminiService != null) {
      _router = AiRouter(
        geminiService: _geminiService!,
        llmService: _llmService!,
        rideLogger: _rideLogger!,
        connectivity: _connectivity!,
      );
    }
  }

  AiAssistant() {
    _messages.add(ChatMessage(
      role: MessageRole.assistant,
      text: 'Musta, rider! Ako si Arangkada AI — your 24/7 road assistant. '
          'I know 100+ topics: traffic rules, platform tips, maintenance, '
          'earnings tracking, emergency info, and more. '
          'Pwede ka rin mag-Taglish!',
      timestamp: DateTime.now(),
      source: ResponseSource.knowledgeBase,
    ));
  }

  List<Map<String, String>> _recentHistory() {
    final history = <Map<String, String>>[];
    final recent = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : _messages;
    for (final msg in recent) {
      history.add({
        'role': msg.role == MessageRole.user ? 'user' : 'model',
        'text': msg.text,
      });
    }
    return history;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      role: MessageRole.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    ));
    _isProcessing = true;
    notifyListeners();

    if (_router != null) {
      try {
        final result = await _router!.route(
          text.trim(),
          history: _recentHistory(),
        );

        if (result.isStream && _llmService != null) {
          // Stream from local LLM
          _isStreaming = true;
          _isProcessing = false;
          final streamMsg = ChatMessage(
            role: MessageRole.assistant,
            text: '',
            timestamp: DateTime.now(),
            source: ResponseSource.localLlm,
            isStreaming: true,
          );
          _messages.add(streamMsg);
          notifyListeners();

          final msgIndex = _messages.length - 1;
          String fullText = '';

          try {
            await for (final token in _llmService!
                .generateResponse(text.trim())
                .timeout(const Duration(seconds: 30))) {
              fullText = token;
              _messages[msgIndex] = ChatMessage(
                role: MessageRole.assistant,
                text: fullText,
                timestamp: streamMsg.timestamp,
                source: ResponseSource.localLlm,
                isStreaming: true,
              );
              notifyListeners();
            }
          } catch (_) {
            if (fullText.isEmpty) {
              fullText = _fallbackText();
            }
          }

          _messages[msgIndex] = ChatMessage(
            role: MessageRole.assistant,
            text: fullText,
            timestamp: streamMsg.timestamp,
            source: ResponseSource.localLlm,
          );
          _isStreaming = false;
          notifyListeners();
          return;
        }

        // Non-streaming response
        await Future.delayed(const Duration(milliseconds: 300));
        _messages.add(ChatMessage(
          role: MessageRole.assistant,
          text: result.response,
          timestamp: DateTime.now(),
          source: result.source,
        ));
        _isProcessing = false;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Router error: $e');
      }
    }

    // Direct fallback if router not ready
    await Future.delayed(const Duration(milliseconds: 300));
    _messages.add(ChatMessage(
      role: MessageRole.assistant,
      text: _fallbackText(),
      timestamp: DateTime.now(),
      source: ResponseSource.ruleBased,
    ));
    _isProcessing = false;
    notifyListeners();
  }

  String _fallbackText() {
    return 'I don\'t have a specific answer for that yet, rider. '
        'But I\'m learning! Here\'s what I can help with:\n\n'
        '🚦 Traffic rules & regulations\n'
        '💰 Earnings & platform comparisons\n'
        '🔧 Motorcycle maintenance\n'
        '🗺️ Navigation & offline maps\n'
        '🆘 Emergency info & numbers\n'
        '📍 Manila landmarks\n'
        '⛽ Fuel tips\n'
        '📋 Legal & LTO requirements\n\n'
        'Try asking: "EDSA motorcycle rules" or "magkano kita ko?"';
  }

  List<String> getSuggestions() {
    if (_messages.length <= 1) {
      return [
        'Magkano kita ko?',
        'EDSA motor ban?',
        'Emergency numbers',
        'Maintenance tips',
      ];
    }

    final last = _messages.last;
    if (last.source == ResponseSource.knowledgeBase) {
      final text = last.text.toLowerCase();
      if (text.contains('edsa') || text.contains('traffic') || text.contains('ban')) {
        return ['Helmet law', 'Number coding', 'Speed limit'];
      }
      if (text.contains('grab') || text.contains('platform') || text.contains('commission')) {
        return ['Best platform?', 'Peak hours', 'Incentive tips'];
      }
      if (text.contains('oil') || text.contains('tire') || text.contains('brake')) {
        return ['Oil change', 'Brake check', 'Tune up schedule'];
      }
      if (text.contains('earnings') || text.contains('kita') || text.contains('ride')) {
        return ['Platform comparison', 'Daily target', 'Fuel cost'];
      }
    }

    return [
      'Traffic rules',
      'Earnings summary',
      'Offline maps',
      'Help',
    ];
  }
}

enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final ResponseSource? source;
  final bool isStreaming;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.source,
    this.isStreaming = false,
  });
}

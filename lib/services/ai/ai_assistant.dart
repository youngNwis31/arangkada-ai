import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ride_logger.dart';
import '../../core/offline/connectivity_monitor.dart';
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

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;
  bool get isStreaming => _isStreaming;

  void updateDependencies({
    required RideLogger rideLogger,
    required ConnectivityMonitor connectivity,
  }) {
    _rideLogger = rideLogger;
    _connectivity = connectivity;
  }

  void setLlmService(LlmService service) {
    _llmService = service;
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

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      role: MessageRole.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    ));
    _isProcessing = true;
    notifyListeners();

    // 1. Knowledge base match (instant)
    final kb = KnowledgeBase.match(text.trim());
    if (kb.found) {
      var response = kb.response;
      if (response.contains('{') && _rideLogger != null && _connectivity != null) {
        final ctx = AiContext(
          rideLogger: _rideLogger!,
          connectivity: _connectivity!,
        );
        response = ctx.fillTemplate(response, ctx.gather());
      }
      await Future.delayed(const Duration(milliseconds: 300));
      _messages.add(ChatMessage(
        role: MessageRole.assistant,
        text: response,
        timestamp: DateTime.now(),
        source: ResponseSource.knowledgeBase,
      ));
      _isProcessing = false;
      notifyListeners();
      return;
    }

    // 2. Local LLM (if downloaded and ready)
    if (_llmService != null && _llmService!.downloadManager.isModelDownloaded) {
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
        await for (final token in _llmService!.generateResponse(text.trim())
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
      } catch (e) {
        if (fullText.isEmpty) {
          fullText = _ruleFallback(text.trim().toLowerCase());
          _messages[msgIndex] = ChatMessage(
            role: MessageRole.assistant,
            text: fullText,
            timestamp: streamMsg.timestamp,
            source: ResponseSource.ruleBased,
          );
        }
      }

      _messages[msgIndex] = ChatMessage(
        role: MessageRole.assistant,
        text: fullText,
        timestamp: streamMsg.timestamp,
        source: fullText == _ruleFallback(text.trim().toLowerCase())
            ? ResponseSource.ruleBased
            : ResponseSource.localLlm,
      );
      _isStreaming = false;
      notifyListeners();
      return;
    }

    // 3. Rule-based fallback
    await Future.delayed(const Duration(milliseconds: 300));
    _messages.add(ChatMessage(
      role: MessageRole.assistant,
      text: _ruleFallback(text.trim().toLowerCase()),
      timestamp: DateTime.now(),
      source: ResponseSource.ruleBased,
    ));
    _isProcessing = false;
    notifyListeners();
  }

  String _ruleFallback(String query) {
    if (query.length < 3) {
      return 'Hmm, can you tell me more? Try asking about traffic rules, '
          'earnings, maintenance, or say "help" for a list of topics!';
    }

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

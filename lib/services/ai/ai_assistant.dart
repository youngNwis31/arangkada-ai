import 'package:flutter/foundation.dart';
import '../ride_logger.dart';
import '../../core/offline/connectivity_monitor.dart';
import 'knowledge_base.dart';
import 'ai_context.dart';

enum ResponseSource { knowledgeBase, ruleBased, localLlm, gemini }

class AiAssistant extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  RideLogger? _rideLogger;
  ConnectivityMonitor? _connectivity;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;

  void updateDependencies({
    required RideLogger rideLogger,
    required ConnectivityMonitor connectivity,
  }) {
    _rideLogger = rideLogger;
    _connectivity = connectivity;
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

    final result = _generateResponse(text.trim());

    await Future.delayed(const Duration(milliseconds: 300));

    _messages.add(ChatMessage(
      role: MessageRole.assistant,
      text: result.response,
      timestamp: DateTime.now(),
      source: result.source,
    ));
    _isProcessing = false;
    notifyListeners();
  }

  ({String response, ResponseSource source}) _generateResponse(String query) {
    // 1. Knowledge base match
    final kb = KnowledgeBase.match(query);
    if (kb.found) {
      var response = kb.response;
      // Fill context variables if needed
      if (response.contains('{') && _rideLogger != null && _connectivity != null) {
        final ctx = AiContext(
          rideLogger: _rideLogger!,
          connectivity: _connectivity!,
        );
        response = ctx.fillTemplate(response, ctx.gather());
      }
      return (response: response, source: ResponseSource.knowledgeBase);
    }

    // 2. (Future: Local LLM goes here)

    // 3. Rule-based fallback
    final fallback = _ruleFallback(query.toLowerCase());
    return (response: fallback, source: ResponseSource.ruleBased);
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
      switch (last.category) {
        case 'traffic_rules':
          return ['Helmet law', 'Number coding', 'Speed limit'];
        case 'platform_policies':
          return ['Best platform?', 'Peak hours', 'Incentive tips'];
        case 'maintenance':
          return ['Oil change', 'Brake check', 'Tune up schedule'];
        case 'earnings':
          return ['Platform comparison', 'Daily target', 'Fuel cost'];
        case 'emergency':
          return ['Accident what to do', 'Nearest hospital', 'Stolen motor'];
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
  final String? category;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.source,
    this.category,
  });
}

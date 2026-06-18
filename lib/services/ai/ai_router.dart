import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/offline/connectivity_monitor.dart';
import '../ride_logger.dart';
import 'ai_assistant.dart';
import 'ai_context.dart';
import 'gemini_service.dart';
import 'knowledge_base.dart';
import 'llm_service.dart';

class AiRouter {
  final GeminiService geminiService;
  final LlmService llmService;
  final RideLogger rideLogger;
  final ConnectivityMonitor connectivity;

  AiRouter({
    required this.geminiService,
    required this.llmService,
    required this.rideLogger,
    required this.connectivity,
  });

  AiContext get _context => AiContext(
        rideLogger: rideLogger,
        connectivity: connectivity,
      );

  Future<({String response, ResponseSource source, bool isStream})> route(
    String query, {
    List<Map<String, String>>? history,
  }) async {
    // 1. Knowledge base match (instant, always available)
    final kb = KnowledgeBase.match(query);
    if (kb.found) {
      var response = kb.response;
      if (response.contains('{')) {
        final ctx = _context;
        response = ctx.fillTemplate(response, ctx.gather());
      }
      return (
        response: response,
        source: ResponseSource.knowledgeBase,
        isStream: false,
      );
    }

    // 2. Gemini Flash (online, best quality)
    if (geminiService.isAvailable) {
      try {
        final ctx = _context.gather();
        final response = await geminiService.generateResponse(
          query,
          context: ctx,
          history: history,
        );
        return (
          response: response,
          source: ResponseSource.gemini,
          isStream: false,
        );
      } catch (e) {
        debugPrint('Gemini failed, falling through: $e');
      }
    }

    // 3. Local LLM (if model downloaded)
    if (llmService.downloadManager.isModelDownloaded) {
      return (
        response: '', // handled via streaming in AiAssistant
        source: ResponseSource.localLlm,
        isStream: true,
      );
    }

    // 4. Rule-based fallback
    return (
      response: _ruleFallback(query),
      source: ResponseSource.ruleBased,
      isStream: false,
    );
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
}

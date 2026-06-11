import 'package:flutter/foundation.dart';

class AiAssistant extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;

  AiAssistant() {
    _messages.add(ChatMessage(
      role: MessageRole.assistant,
      text: 'Musta, rider! Ako si Arangkada AI — your 24/7 road assistant. '
          'Ask me about routes, traffic, hazards, or directions. '
          'Pwede ka rin mag-Taglish!',
      timestamp: DateTime.now(),
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

    // Offline rule-based responses for v0.01.
    // Future: Replace with local SLM (Qwen-1.5B / Gemma-2B via llama_flutter)
    final response = _generateOfflineResponse(text.trim().toLowerCase());

    await Future.delayed(const Duration(milliseconds: 400));

    _messages.add(ChatMessage(
      role: MessageRole.assistant,
      text: response,
      timestamp: DateTime.now(),
    ));
    _isProcessing = false;
    notifyListeners();
  }

  String _generateOfflineResponse(String query) {
    if (_matches(query, ['traffic', 'trapik', 'congestion', 'siksikan'])) {
      return 'I can check traffic conditions along your route. '
          'Set a destination first and I\'ll score each route by congestion level. '
          'The AI Recommended route avoids the heaviest traffic.';
    }

    if (_matches(query, ['lubak', 'pothole', 'butas', 'road damage'])) {
      return 'To report a pothole, use the hazard button (warning icon) on the map. '
          'One tap logs it with your GPS coordinates. '
          'Reports sync to other riders when you\'re back online.';
    }

    if (_matches(query, ['baha', 'flood', 'tubig', 'binabaha'])) {
      return 'Flooding reports are saved offline and shared with other riders. '
          'I\'ll re-route you around reported flood zones when available. '
          'Stay safe — avoid water higher than your exhaust pipe.';
    }

    if (_matches(query, ['shortcut', 'malapit', 'shortcut', 'daan'])) {
      return 'I analyze Mapbox route alternatives and score them by distance, '
          'duration, and traffic. The "Shortest Distance" option shows the '
          'most direct path. Set your destination to see all options.';
    }

    if (_matches(query, ['offline', 'walang signal', 'no internet', 'dead zone'])) {
      return 'Arangkada AI works offline! Pre-download maps for your area '
          'via the Offline Maps screen. Hazard reports are saved locally '
          'and auto-sync when signal returns. Voice commands work offline too.';
    }

    if (_matches(query, ['gas', 'gasolinahan', 'petron', 'shell', 'fuel'])) {
      return 'Search for "gas station" or "Petron" in the search bar — '
          'Mapbox will show nearby fuel stations. I\'ll include them '
          'in your route if needed.';
    }

    if (_matches(query, ['help', 'tulong', 'paano', 'how'])) {
      return 'Here\'s what I can help with:\n'
          '• Set destinations and get AI-optimized routes\n'
          '• Report hazards (lubak, baha, checkpoint)\n'
          '• Download offline maps for dead zones\n'
          '• Voice navigation directions\n'
          '• Traffic-aware route scoring\n\n'
          'Just ask in English or Taglish!';
    }

    return 'Got it, rider! In v0.01, I handle route questions, hazard reports, '
        'and navigation help. For more complex queries, a local AI model '
        'is coming in the next update. Anything else?';
  }

  bool _matches(String query, List<String> keywords) {
    return keywords.any((k) => query.contains(k));
  }
}

enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

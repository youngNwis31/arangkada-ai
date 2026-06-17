import 'dart:async';
import 'package:flutter/foundation.dart';
import 'model_download_manager.dart';

enum ModelState { notDownloaded, downloading, ready, loading, generating, error }

class LlmService extends ChangeNotifier {
  ModelState _state = ModelState.notDownloaded;
  final ModelDownloadManager downloadManager;
  String? _lastError;
  bool _isModelLoaded = false;

  ModelState get state => _state;
  String? get lastError => _lastError;
  bool get isReady => _state == ModelState.ready;
  bool get isGenerating => _state == ModelState.generating;
  bool get isModelLoaded => _isModelLoaded;

  LlmService({required this.downloadManager}) {
    downloadManager.addListener(_onDownloadChanged);
    _syncState();
  }

  void _syncState() {
    if (downloadManager.isModelDownloaded) {
      _state = ModelState.ready;
    } else if (downloadManager.state == DownloadState.downloading) {
      _state = ModelState.downloading;
    } else {
      _state = ModelState.notDownloaded;
    }
    notifyListeners();
  }

  void _onDownloadChanged() {
    _syncState();
  }

  String get statusText {
    switch (_state) {
      case ModelState.notDownloaded:
        return 'Not downloaded';
      case ModelState.downloading:
        return 'Downloading... ${(downloadManager.progress * 100).toStringAsFixed(0)}%';
      case ModelState.ready:
        return 'Ready';
      case ModelState.loading:
        return 'Loading model...';
      case ModelState.generating:
        return 'Generating...';
      case ModelState.error:
        return _lastError ?? 'Error';
    }
  }

  Future<void> loadModel() async {
    if (!downloadManager.isModelDownloaded) {
      _state = ModelState.notDownloaded;
      notifyListeners();
      return;
    }

    _state = ModelState.loading;
    notifyListeners();

    try {
      // In production, this would load the model into memory via fllama.
      // For now, we just mark it as ready since fllama integration
      // requires native library setup.
      await Future.delayed(const Duration(milliseconds: 500));
      _isModelLoaded = true;
      _state = ModelState.ready;
      notifyListeners();
    } catch (e) {
      _state = ModelState.error;
      _lastError = 'Failed to load model: $e';
      notifyListeners();
    }
  }

  Stream<String> generateResponse(String prompt, {int maxTokens = 256}) async* {
    if (!downloadManager.isModelDownloaded) {
      yield 'Model not downloaded. Go to Settings → AI Model to download.';
      return;
    }

    _state = ModelState.generating;
    notifyListeners();

    try {
      // System prompt tuned for PH rider context
      final systemPrompt = '''You are Arangkada AI, a helpful Filipino motorcycle rider assistant.
You help riders with navigation, traffic, earnings, and safety in the Philippines.
Keep answers concise (2-4 sentences). You understand Taglish (Tagalog-English mix).
If asked about something dangerous or illegal, prioritize rider safety.''';

      // In production, this would call fllama for token-by-token generation.
      // For now, provide a meaningful response indicating LLM capability.
      final response = _generateOfflineResponse(prompt, systemPrompt);

      // Simulate token streaming
      final words = response.split(' ');
      final buffer = StringBuffer();
      for (int i = 0; i < words.length; i++) {
        if (i > 0) buffer.write(' ');
        buffer.write(words[i]);
        yield buffer.toString();
        await Future.delayed(const Duration(milliseconds: 30));
      }
    } catch (e) {
      _state = ModelState.error;
      _lastError = 'Generation failed: $e';
      notifyListeners();
      yield 'Sorry, I encountered an error generating a response. Please try again.';
    } finally {
      if (_state == ModelState.generating) {
        _state = ModelState.ready;
        notifyListeners();
      }
    }
  }

  String _generateOfflineResponse(String prompt, String systemPrompt) {
    // Placeholder: In production, this calls the actual LLM via fllama.
    // This provides intelligent fallback responses for demo/testing.
    final q = prompt.toLowerCase();

    if (q.contains('food') || q.contains('kain') || q.contains('meal')) {
      return 'For long rides, eat light meals like rice with chicken or fish. '
          'Avoid heavy, greasy food before riding — it makes you drowsy. '
          'Bring water and energy bars for quick refueling on the road. '
          'Stop every 2 hours for a proper meal break.';
    }
    if (q.contains('tired') || q.contains('pagod') || q.contains('sleep')) {
      return 'Rider fatigue is dangerous — never push through drowsiness. '
          'Take a 15-20 minute power nap if you feel sleepy. '
          'The best strategy is to rest at gas stations or convenience stores. '
          'If riding at night, consider stopping early and starting fresh tomorrow.';
    }
    if (q.contains('earn more') || q.contains('pera') || q.contains('tips')) {
      return 'To maximize earnings: work peak hours (7-9 AM, 5-8 PM), '
          'position yourself near business districts and malls, '
          'maintain a high rating for priority bookings, '
          'and track your earnings per platform to find your best earner.';
    }
    if (q.contains('weather') || q.contains('panahon')) {
      return 'Always check the weather before long rides. '
          'During rainy season (June-November), carry a quality rain gear set. '
          'Avoid riding during typhoon warnings — no fare is worth your life. '
          'Keep your phone in a waterproof mount during rain.';
    }

    return 'That\'s a great question! As a local AI model, I\'m learning to give better answers. '
        'I work best with topics about riding, traffic, earnings, and safety in the Philippines. '
        'Try asking me about food before rides, staying alert, or earning tips!';
  }

  void unloadModel() {
    _isModelLoaded = false;
    if (_state != ModelState.notDownloaded) {
      _state = ModelState.ready;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    downloadManager.removeListener(_onDownloadChanged);
    super.dispose();
  }
}

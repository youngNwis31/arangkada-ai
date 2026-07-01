import '../../../services/ai/voice_service.dart';

class VoiceCommandResult {
  final bool matched;
  final String message;

  const VoiceCommandResult.matched(this.message) : matched = true;
  const VoiceCommandResult.notMatched() : matched = false, message = '';
}

abstract class VoiceCommandHandler {
  Future<VoiceCommandResult> tryHandle(String query, String originalText);

  Future<void> respond(String message) async {
    await VoiceService.speak(message);
  }
}

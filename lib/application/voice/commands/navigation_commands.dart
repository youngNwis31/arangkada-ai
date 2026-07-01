import '../../../services/ai/voice_service.dart';
import '../../../services/mapbox_service.dart';
import '../../../services/navigation_provider.dart';
import 'voice_command_handler.dart';

class NavigationCommandHandler extends VoiceCommandHandler {
  NavigationProvider? nav;

  static final _navPatterns = [
    RegExp(r'^(?:navigate|go|directions?|take me|drive)\s+to\s+(.+)$',
        caseSensitive: false),
    RegExp(r'^(?:papunta|punta|daan)\s+(?:sa|ng)\s+(.+)$',
        caseSensitive: false),
  ];

  @override
  Future<VoiceCommandResult> tryHandle(String q, String originalText) async {
    for (final pattern in _navPatterns) {
      final match = pattern.firstMatch(q);
      if (match != null) {
        final place = match.group(1)!.trim();
        return _handleNavigation(place);
      }
    }
    return const VoiceCommandResult.notMatched();
  }

  Future<VoiceCommandResult> _handleNavigation(String place) async {
    await VoiceService.speak('Searching for $place');

    try {
      final results = await MapboxService.searchPlaces(place);
      if (results.isNotEmpty) {
        final dest = results.first;
        nav?.setDestination(dest);
        await VoiceService.speak('Navigating to ${dest.name}');
        return VoiceCommandResult.matched('Navigating to ${dest.name}');
      } else {
        await VoiceService.speak("Sorry, I couldn't find $place");
        return VoiceCommandResult.matched('Place not found: $place');
      }
    } catch (_) {
      await VoiceService.speak('Search failed. Try again, rider.');
      return const VoiceCommandResult.matched('Search failed — try again');
    }
  }
}

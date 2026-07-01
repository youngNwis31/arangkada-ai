import '../../../services/ai/voice_service.dart';
import '../../../services/ride_logger.dart';
import 'voice_command_handler.dart';

class RideCommandHandler extends VoiceCommandHandler {
  RideLogger? rideLogger;

  static final _ridePatterns = [
    RegExp(r'^(?:log|book|end)\s+(?:ride\s+)?(\w+)\s+(\d+)',
        caseSensitive: false),
  ];

  static const _earningsKeywords = [
    'earnings today',
    'earnings',
    'kita ko',
    'kita today',
    'how much today',
    'magkano kita',
    'income today',
  ];

  @override
  Future<VoiceCommandResult> tryHandle(String q, String originalText) async {
    for (final pattern in _ridePatterns) {
      final match = pattern.firstMatch(q);
      if (match != null) {
        final platform = match.group(1)!.trim();
        final amount = double.tryParse(match.group(2)!) ?? 0;
        if (amount > 0) {
          return _handleRideLog(platform, amount);
        }
      }
    }

    for (final keyword in _earningsKeywords) {
      if (q.contains(keyword)) {
        return _handleEarningsQuery();
      }
    }

    return const VoiceCommandResult.notMatched();
  }

  VoiceCommandResult _handleRideLog(String platform, double amount) {
    final normalized = _normalizePlatform(platform);
    rideLogger?.logQuickRide(platform: normalized, earning: amount);
    VoiceService.speak(
        'Ride logged! ${amount.toStringAsFixed(0)} pesos on $normalized');
    return VoiceCommandResult.matched(
        'Logged ₱${amount.toStringAsFixed(0)} on $normalized');
  }

  VoiceCommandResult _handleEarningsQuery() {
    final earnings = rideLogger?.todayEarnings ?? 0;
    final rides = rideLogger?.todayRideCount ?? 0;
    final text = rides > 0
        ? 'Today you earned ${earnings.toStringAsFixed(0)} pesos from $rides ${rides == 1 ? "ride" : "rides"}'
        : 'No rides logged today yet';
    VoiceService.speak(text);
    return VoiceCommandResult.matched(text);
  }

  String _normalizePlatform(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('grab')) return 'Grab';
    if (lower.contains('food') || lower.contains('panda')) return 'FoodPanda';
    if (lower.contains('lala') || lower.contains('move')) return 'Lalamove';
    if (lower.contains('angkas')) return 'Angkas';
    if (lower.contains('joy')) return 'JoyRide';
    if (lower.contains('moveit')) return 'MoveIt';
    return input[0].toUpperCase() + input.substring(1);
  }
}

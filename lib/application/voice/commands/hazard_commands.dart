import '../../../services/ai/voice_service.dart';
import '../../../services/hazard_service.dart';
import '../../../services/navigation_provider.dart';
import '../../../models/hazard_report.dart';
import 'voice_command_handler.dart';

class HazardCommandHandler extends VoiceCommandHandler {
  NavigationProvider? nav;

  static const _hazardMap = {
    'pothole': HazardType.pothole,
    'lubak': HazardType.pothole,
    'flood': HazardType.flooding,
    'baha': HazardType.flooding,
    'accident': HazardType.accident,
    'aksidente': HazardType.accident,
    'checkpoint': HazardType.checkpoint,
    'road closure': HazardType.roadClosure,
    'sarado': HazardType.roadClosure,
    'construction': HazardType.construction,
    'gawa': HazardType.construction,
  };

  @override
  Future<VoiceCommandResult> tryHandle(String q, String originalText) async {
    if (q.startsWith('report ') ||
        q.startsWith('may ') ||
        q.startsWith('meron ')) {
      for (final entry in _hazardMap.entries) {
        if (q.contains(entry.key)) {
          return _handleHazardReport(entry.value);
        }
      }
    }

    for (final entry in _hazardMap.entries) {
      if (q == entry.key) {
        return _handleHazardReport(entry.value);
      }
    }

    return const VoiceCommandResult.notMatched();
  }

  VoiceCommandResult _handleHazardReport(HazardType type) {
    final pos = nav?.currentLocation;
    if (pos != null) {
      HazardService.reportHazard(
        type: type,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      VoiceService.speak('${type.english} reported! Ingat, rider.');
      return VoiceCommandResult.matched(
          '${type.english} reported at current location');
    } else {
      VoiceService.speak('No GPS location available. Try again.');
      return const VoiceCommandResult.matched(
          'Cannot report — no GPS location');
    }
  }
}

import '../../../services/ai/voice_service.dart';
import '../../../services/crash_detector.dart';
import '../../../services/fatigue_monitor.dart';
import '../../../services/navigation_provider.dart';
import '../../../services/night_mode_provider.dart';
import '../../../services/speed_monitor.dart';
import 'voice_command_handler.dart';

class SafetyCommandHandler extends VoiceCommandHandler {
  NavigationProvider? nav;
  SpeedMonitor? speedMonitor;
  FatigueMonitor? fatigueMonitor;
  CrashDetector? crashDetector;
  NightModeProvider? nightMode;

  @override
  Future<VoiceCommandResult> tryHandle(String q, String originalText) async {
    if (q == 'reroute' ||
        q.contains('ibang daan') ||
        q.contains('ibang route')) {
      return _handleReroute();
    }

    if (q.contains('speed ko') ||
        q.contains('bilis ko') ||
        q == 'speed' ||
        q.contains('how fast')) {
      return _handleSpeedQuery();
    }

    if (q.contains('gaano kalayo') ||
        q.contains('kalayo pa') ||
        q == 'eta' ||
        q.contains('how far') ||
        q.contains('malayo pa')) {
      return _handleEtaQuery();
    }

    if (q.contains('night mode') ||
        q.contains('gabi mode') ||
        (q.contains('night') && q.contains('mode'))) {
      return _handleNightMode();
    }

    if (q == 'pahinga' ||
        q == 'rest' ||
        q.contains('take a break') ||
        q.contains('mag pahinga') ||
        q.contains('magpahinga')) {
      return _handleRest();
    }

    if (q.contains("i'm ok") ||
        q.contains('im ok') ||
        q.contains('ok lang') ||
        q.contains('okay lang') ||
        q.contains("i am ok") ||
        q.contains('ok ako')) {
      return _handleDismissCrash();
    }

    if (q == 'help' ||
        q == 'tulong' ||
        q == 'sos' ||
        q.contains('emergency') ||
        q.contains('saklolo')) {
      return _handleSos();
    }

    if (q == 'status' ||
        q == 'sitrep' ||
        q.contains('status ko') ||
        q.contains('anong nangyayari')) {
      return _handleStatus();
    }

    return const VoiceCommandResult.notMatched();
  }

  Future<VoiceCommandResult> _handleReroute() async {
    if (nav == null || !nav!.isNavigating) {
      await VoiceService.speak('Hindi ka nag-navigate, rider.');
      return const VoiceCommandResult.matched('Not navigating right now');
    }
    await VoiceService.speak('Hanap ng ibang daan...');

    try {
      final dest = nav!.destination;
      final origin = nav!.origin;
      if (dest == null || origin == null) {
        return const VoiceCommandResult.matched('No route to reroute');
      }
      nav!.stopNavigation();
      await nav!.fetchRoutes();
      if (nav!.routes.length > 1) {
        nav!.selectRoute(1);
      }
      await nav!.startNavigation();
      await VoiceService.speak('New route! Tara na, rider.');
      return const VoiceCommandResult.matched('New route found! Tara na.');
    } catch (_) {
      await VoiceService.speak('Sorry, walang ibang daan.');
      return const VoiceCommandResult.matched('Reroute failed');
    }
  }

  VoiceCommandResult _handleSpeedQuery() {
    final kmh = speedMonitor?.currentSpeedKmh.toInt() ?? 0;
    final limit = speedMonitor?.speedLimitKmh.toInt() ?? 60;
    VoiceService.speak('$kmh kilometers per hour. Limit is $limit.');
    return VoiceCommandResult.matched('$kmh km/h. Limit is $limit.');
  }

  VoiceCommandResult _handleEtaQuery() {
    final engine = nav?.navEngine;
    if (engine == null || !engine.isNavigating) {
      VoiceService.speak('Hindi ka nag-navigate, rider.');
      return const VoiceCommandResult.matched('Not navigating');
    }
    final dist = engine.totalRemainingDistance;
    final distText = dist >= 1000
        ? '${(dist / 1000).toStringAsFixed(1)} km'
        : '${dist.toInt()} meters';
    final eta = engine.etaText;
    final arrival = engine.etaTimeText;
    VoiceService.speak('$distText pa. $eta, arrival $arrival.');
    return VoiceCommandResult.matched('$distText left. ETA $eta ($arrival)');
  }

  VoiceCommandResult _handleNightMode() {
    if (nightMode == null) {
      return const VoiceCommandResult.matched('Night mode not available');
    }
    nightMode!.toggle();
    final on = nightMode!.isNightMode;
    VoiceService.speak('Night mode ${on ? "on" : "off"}, rider.');
    return VoiceCommandResult.matched('Night mode ${on ? "ON" : "OFF"}');
  }

  VoiceCommandResult _handleRest() {
    fatigueMonitor?.markRest();
    VoiceService.speak('Rest timer reset. Pahinga muna, rider!');
    return const VoiceCommandResult.matched('Rest timer reset');
  }

  VoiceCommandResult _handleDismissCrash() {
    crashDetector?.dismiss();
    VoiceService.speak('Ok, glad you are ok, rider!');
    return const VoiceCommandResult.matched('Crash alert dismissed');
  }

  VoiceCommandResult _handleSos() {
    crashDetector?.triggerSos();
    return const VoiceCommandResult.matched('SOS triggered!');
  }

  VoiceCommandResult _handleStatus() {
    final parts = <String>[];

    if (nav?.isNavigating == true) {
      final engine = nav!.navEngine;
      final dist = engine.totalRemainingDistance;
      final distText = dist >= 1000
          ? '${(dist / 1000).toStringAsFixed(1)} km'
          : '${dist.toInt()} m';
      parts.add('$distText left, ETA ${engine.etaText}');
    } else {
      parts.add('Not navigating');
    }

    final kmh = speedMonitor?.currentSpeedKmh.toInt() ?? 0;
    parts.add('Speed: $kmh km/h');

    if (fatigueMonitor?.isRiding == true) {
      parts.add('Riding: ${fatigueMonitor!.rideTimeText}');
    }

    final summary = parts.join('. ');
    VoiceService.speak(summary);
    return VoiceCommandResult.matched(summary);
  }
}

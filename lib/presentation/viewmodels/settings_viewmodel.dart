import 'package:flutter/foundation.dart';
import '../../domain/repositories/i_rider_settings_repository.dart';
import '../../services/night_mode_provider.dart';
import '../../services/speed_monitor.dart';
import '../../services/theme_provider.dart';
import '../../services/voice_command_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final IRiderSettingsRepository _settings;
  final ThemeProvider themeProvider;
  final NightModeProvider nightMode;
  final SpeedMonitor speedMonitor;
  final VoiceCommandService voiceCommand;

  SettingsViewModel({
    required IRiderSettingsRepository settings,
    required this.themeProvider,
    required this.nightMode,
    required this.speedMonitor,
    required this.voiceCommand,
  }) : _settings = settings;

  Future<void> setSpeedLimit(double kmh) async {
    speedMonitor.setSpeedLimit(kmh);
    await _settings.set('speed_limit_kmh', kmh.toStringAsFixed(0));
    notifyListeners();
  }

  void toggleNightMode() {
    nightMode.toggle();
    notifyListeners();
  }

  void toggleAutoListen() {
    voiceCommand.toggleAutoListen();
    notifyListeners();
  }

  void setStatusInterval(int minutes) {
    voiceCommand.setStatusInterval(minutes);
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../core/database/local_database.dart';

class NightModeProvider extends ChangeNotifier {
  bool _isNightMode = false;

  bool get isNightMode => _isNightMode;

  NightModeProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final raw = await LocalDatabase.getRiderSetting('night_mode_enabled');
    if (raw == 'true') {
      _isNightMode = true;
      notifyListeners();
    }
  }

  void toggle() {
    _isNightMode = !_isNightMode;
    LocalDatabase.setRiderSetting(
      'night_mode_enabled',
      _isNightMode.toString(),
    );
    notifyListeners();
    debugPrint('NightMode: ${_isNightMode ? "ON" : "OFF"}');
  }

  void setNightMode(bool value) {
    if (_isNightMode == value) return;
    _isNightMode = value;
    LocalDatabase.setRiderSetting(
      'night_mode_enabled',
      _isNightMode.toString(),
    );
    notifyListeners();
  }

  bool shouldSuggestNightMode() {
    final hour = DateTime.now().hour;
    return (hour >= 18 || hour < 5) && !_isNightMode;
  }
}

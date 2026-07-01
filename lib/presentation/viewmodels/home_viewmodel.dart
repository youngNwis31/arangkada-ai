import 'package:flutter/foundation.dart';
import '../../services/navigation_provider.dart';
import '../../services/weather_service.dart';

class HomeViewModel extends ChangeNotifier {
  final NavigationProvider navProvider;
  final WeatherService weatherService;

  HomeViewModel({
    required this.navProvider,
    required this.weatherService,
  });

  Future<void> refreshLocation() async {
    await navProvider.initLocation();
    notifyListeners();
  }

  Future<void> refreshWeather() async {
    final loc = navProvider.currentLocation;
    if (loc != null) {
      await weatherService.fetchWeather(loc.latitude, loc.longitude);
    }
    notifyListeners();
  }
}

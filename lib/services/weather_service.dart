import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../core/database/local_database.dart';
import '../core/offline/connectivity_monitor.dart';

class WeatherService extends ChangeNotifier {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _refreshMinutes = 30;

  WeatherData? _currentWeather;
  List<HourlyForecast> _forecast = [];
  bool _isLoading = false;
  bool _fromCache = false;
  Timer? _refreshTimer;
  ConnectivityMonitor? _connectivity;

  WeatherData? get currentWeather => _currentWeather;
  List<HourlyForecast> get forecast => _forecast;
  bool get isLoading => _isLoading;
  bool get fromCache => _fromCache;
  bool get hasData => _currentWeather != null;
  bool get isRaining => _currentWeather?.isRaining ?? false;

  bool get isFloodRisk {
    if (_currentWeather?.isHeavyRain == true) return true;
    return _forecast.any((f) => f.heavyRain);
  }

  void updateConnectivity(ConnectivityMonitor connectivity) {
    _connectivity = connectivity;
  }

  Future<void> fetchWeather(double lat, double lng) async {
    if (_connectivity?.isOnline == true) {
      await _fetchFromApi(lat, lng);
    } else {
      await _loadFromCache();
    }
  }

  Future<void> _fetchFromApi(double lat, double lng) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'current': 'temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,rain',
        'hourly': 'temperature_2m,weather_code,precipitation_probability,rain',
        'timezone': 'Asia/Manila',
        'forecast_hours': '12',
      });

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        await _loadFromCache();
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      _currentWeather = WeatherData.fromOpenMeteo(data);
      _forecast = _parseHourlyForecast(data);
      _fromCache = false;

      await LocalDatabase.insertWeatherCache(
          _currentWeather!.toCache(lat, lng));
    } catch (_) {
      await _loadFromCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<HourlyForecast> _parseHourlyForecast(Map<String, dynamic> data) {
    final hourly = data['hourly'] as Map<String, dynamic>?;
    if (hourly == null) return [];

    final times = (hourly['time'] as List?) ?? [];
    final temps = (hourly['temperature_2m'] as List?) ?? [];
    final codes = (hourly['weather_code'] as List?) ?? [];
    final rainProbs = (hourly['precipitation_probability'] as List?) ?? [];
    final rainAmounts = (hourly['rain'] as List?) ?? [];

    final forecasts = <HourlyForecast>[];
    for (int i = 0; i < times.length && i < 12; i++) {
      forecasts.add(HourlyForecast(
        time: DateTime.tryParse(times[i].toString()) ?? DateTime.now(),
        temperature: (temps.length > i ? temps[i] as num : 0).toDouble(),
        weatherCode: (codes.length > i ? codes[i] as num : 0).toInt(),
        rainProbability: (rainProbs.length > i ? rainProbs[i] as num : 0).toDouble(),
        rainMm: (rainAmounts.length > i ? rainAmounts[i] as num : 0).toDouble(),
      ));
    }
    return forecasts;
  }

  Future<void> _loadFromCache() async {
    try {
      final row = await LocalDatabase.getLatestWeather();
      if (row != null) {
        _currentWeather = WeatherData.fromCache(row);
        _fromCache = true;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void startAutoRefresh(double lat, double lng) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: _refreshMinutes),
      (_) => fetchWeather(lat, lng),
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

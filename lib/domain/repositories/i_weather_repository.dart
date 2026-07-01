import '../entities/weather.dart';

abstract class IWeatherRepository {
  Future<void> cacheWeather(Weather weather, double lat, double lng);
  Future<Weather?> getLatestCached();
}

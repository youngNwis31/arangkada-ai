import '../../core/database/local_database.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/i_weather_repository.dart';

class SqliteWeatherRepository implements IWeatherRepository {
  @override
  Future<void> cacheWeather(Weather weather, double lat, double lng) =>
      LocalDatabase.insertWeatherCache({
        'latitude': lat,
        'longitude': lng,
        'temperature': weather.temperature,
        'weather_code': weather.weatherCode,
        'wind_speed': weather.windSpeed,
        'humidity': weather.humidity,
        'rain_mm': weather.rainMm,
        'fetched_at': weather.fetchedAt.toIso8601String(),
      });

  @override
  Future<Weather?> getLatestCached() async {
    final row = await LocalDatabase.getLatestWeather();
    if (row == null) return null;
    return Weather(
      temperature: (row['temperature'] as num?)?.toDouble() ?? 0,
      weatherCode: (row['weather_code'] as num?)?.toInt() ?? 0,
      windSpeed: (row['wind_speed'] as num?)?.toDouble() ?? 0,
      humidity: (row['humidity'] as num?)?.toInt() ?? 0,
      rainMm: (row['rain_mm'] as num?)?.toDouble() ?? 0,
      fetchedAt: DateTime.parse(row['fetched_at'] as String),
    );
  }
}

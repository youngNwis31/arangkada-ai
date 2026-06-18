import 'package:flutter/material.dart';

class WeatherData {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final double rainMm;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    required this.rainMm,
    required this.fetchedAt,
  });

  bool get isRaining => rainMm > 0 || (weatherCode >= 51 && weatherCode <= 67);
  bool get isHeavyRain => rainMm > 5 || weatherCode >= 63;

  String get description => descriptionForCode(weatherCode);
  IconData get icon => iconForCode(weatherCode);

  factory WeatherData.fromOpenMeteo(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return WeatherData(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      rainMm: (current['rain'] as num?)?.toDouble() ?? 0,
      fetchedAt: DateTime.now(),
    );
  }

  factory WeatherData.fromCache(Map<String, dynamic> row) => WeatherData(
        temperature: (row['temperature'] as num?)?.toDouble() ?? 0,
        weatherCode: (row['weather_code'] as num?)?.toInt() ?? 0,
        windSpeed: (row['wind_speed'] as num?)?.toDouble() ?? 0,
        humidity: (row['humidity'] as num?)?.toInt() ?? 0,
        rainMm: (row['rain_mm'] as num?)?.toDouble() ?? 0,
        fetchedAt: DateTime.parse(row['fetched_at'] as String),
      );

  Map<String, dynamic> toCache(double lat, double lng) => {
        'latitude': lat,
        'longitude': lng,
        'temperature': temperature,
        'weather_code': weatherCode,
        'wind_speed': windSpeed,
        'humidity': humidity,
        'rain_mm': rainMm,
        'fetched_at': fetchedAt.toIso8601String(),
      };

  static String descriptionForCode(int code) => switch (code) {
        0 => 'Clear sky',
        1 => 'Mainly clear',
        2 => 'Partly cloudy',
        3 => 'Overcast',
        45 || 48 => 'Foggy',
        51 => 'Light drizzle',
        53 => 'Drizzle',
        55 => 'Heavy drizzle',
        61 => 'Light rain / Ambon',
        63 => 'Rain / Ulan',
        65 => 'Heavy rain / Malakas na ulan',
        66 || 67 => 'Freezing rain',
        71 || 73 || 75 => 'Snow',
        80 => 'Light showers',
        81 => 'Showers / Buhos',
        82 => 'Heavy showers / Malakas na buhos',
        95 => 'Thunderstorm / Kidlat',
        96 || 99 => 'Thunderstorm with hail',
        _ => 'Unknown',
      };

  static IconData iconForCode(int code) => switch (code) {
        0 => Icons.wb_sunny,
        1 || 2 => Icons.cloud_queue,
        3 => Icons.cloud,
        45 || 48 => Icons.foggy,
        51 || 53 || 55 || 61 || 80 => Icons.grain,
        63 || 65 || 81 || 82 => Icons.water_drop,
        66 || 67 => Icons.ac_unit,
        71 || 73 || 75 => Icons.ac_unit,
        95 || 96 || 99 => Icons.thunderstorm,
        _ => Icons.cloud,
      };
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final double rainProbability;
  final double rainMm;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.rainProbability,
    required this.rainMm,
  });

  bool get willRain => rainProbability > 50 || rainMm > 0;
  bool get heavyRain => rainMm > 5;
}

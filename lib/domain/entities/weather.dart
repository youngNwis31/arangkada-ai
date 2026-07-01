class Weather {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final double rainMm;
  final DateTime fetchedAt;

  const Weather({
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

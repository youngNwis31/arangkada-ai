enum RidePlatform {
  grab('Grab', '🟢'),
  foodPanda('FoodPanda', '🩷'),
  lalamove('Lalamove', '🟠'),
  angkas('Angkas', '🔵'),
  joyRide('JoyRide', '🟡'),
  moveIt('MoveIt', '🟣'),
  other('Other', '⚪');

  final String label;
  final String emoji;
  const RidePlatform(this.label, this.emoji);
}

class RideLog {
  final String id;
  final RidePlatform platform;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final double? originLat;
  final double? originLng;
  final double? destLat;
  final double? destLng;
  final double estimatedEarning;
  final double fuelCost;
  final String? notes;

  const RideLog({
    required this.id,
    required this.platform,
    required this.startTime,
    this.endTime,
    this.distanceKm = 0,
    this.originLat,
    this.originLng,
    this.destLat,
    this.destLng,
    this.estimatedEarning = 0,
    this.fuelCost = 0,
    this.notes,
  });

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);

  String get durationText {
    final d = duration;
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  String get distanceText => '${distanceKm.toStringAsFixed(1)} km';

  double get netEarning => estimatedEarning - fuelCost;

  Map<String, dynamic> toDb() => {
        'id': id,
        'platform': platform.name,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'distance_km': distanceKm,
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
        'estimated_earning': estimatedEarning,
        'fuel_cost': fuelCost,
        'notes': notes,
      };

  factory RideLog.fromDb(Map<String, dynamic> row) => RideLog(
        id: row['id'] as String,
        platform: RidePlatform.values.firstWhere(
          (p) => p.name == row['platform'],
          orElse: () => RidePlatform.other,
        ),
        startTime: DateTime.parse(row['start_time'] as String),
        endTime: row['end_time'] != null
            ? DateTime.parse(row['end_time'] as String)
            : null,
        distanceKm: (row['distance_km'] as num?)?.toDouble() ?? 0,
        originLat: (row['origin_lat'] as num?)?.toDouble(),
        originLng: (row['origin_lng'] as num?)?.toDouble(),
        destLat: (row['dest_lat'] as num?)?.toDouble(),
        destLng: (row['dest_lng'] as num?)?.toDouble(),
        estimatedEarning: (row['estimated_earning'] as num?)?.toDouble() ?? 0,
        fuelCost: (row['fuel_cost'] as num?)?.toDouble() ?? 0,
        notes: row['notes'] as String?,
      );

  RideLog copyWith({
    DateTime? endTime,
    double? distanceKm,
    double? destLat,
    double? destLng,
    double? estimatedEarning,
    double? fuelCost,
    String? notes,
  }) =>
      RideLog(
        id: id,
        platform: platform,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        distanceKm: distanceKm ?? this.distanceKm,
        originLat: originLat,
        originLng: originLng,
        destLat: destLat ?? this.destLat,
        destLng: destLng ?? this.destLng,
        estimatedEarning: estimatedEarning ?? this.estimatedEarning,
        fuelCost: fuelCost ?? this.fuelCost,
        notes: notes ?? this.notes,
      );
}

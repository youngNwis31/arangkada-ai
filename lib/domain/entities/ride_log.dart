import '../enums/ride_platform.dart';

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

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  String get durationText {
    final d = duration;
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  String get distanceText => '${distanceKm.toStringAsFixed(1)} km';

  double get netEarning => estimatedEarning - fuelCost;

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

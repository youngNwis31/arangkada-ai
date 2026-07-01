import '../enums/hazard_type.dart';

class Hazard {
  final String id;
  final HazardType type;
  final double latitude;
  final double longitude;
  final String? description;
  final String? voiceNotePath;
  final DateTime createdAt;
  final bool synced;

  const Hazard({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.description,
    this.voiceNotePath,
    required this.createdAt,
    this.synced = false,
  });
}

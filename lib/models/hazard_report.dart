enum HazardType {
  pothole('Pothole', 'LUBAK'),
  flooding('Flooding', 'BAHA'),
  checkpoint('Checkpoint', 'CHECKPOINT'),
  accident('Accident', 'AKSIDENTE'),
  roadClosure('Road Closure', 'SARADO'),
  construction('Construction', 'GAWA');

  final String english;
  final String tagalog;
  const HazardType(this.english, this.tagalog);
}

class HazardReport {
  final String id;
  final HazardType type;
  final double latitude;
  final double longitude;
  final String? description;
  final String? voiceNotePath;
  final DateTime createdAt;
  final bool synced;

  const HazardReport({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.description,
    this.voiceNotePath,
    required this.createdAt,
    this.synced = false,
  });

  Map<String, dynamic> toDb() => {
        'id': id,
        'type': type.name,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'voice_note_path': voiceNotePath,
        'created_at': createdAt.toIso8601String(),
        'synced': synced ? 1 : 0,
      };

  factory HazardReport.fromDb(Map<String, dynamic> row) => HazardReport(
        id: row['id'] as String,
        type: HazardType.values.firstWhere((t) => t.name == row['type']),
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        description: row['description'] as String?,
        voiceNotePath: row['voice_note_path'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        synced: row['synced'] == 1,
      );
}

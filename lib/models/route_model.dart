import 'location_model.dart';

class RouteStep {
  final String instruction;
  final double distance;
  final double duration;
  final String? modifier;
  final String? maneuverType;
  final double? maneuverLat;
  final double? maneuverLng;

  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.modifier,
    this.maneuverType,
    this.maneuverLat,
    this.maneuverLng,
  });

  Map<String, dynamic> toJson() => {
        'instruction': instruction,
        'distance': distance,
        'duration': duration,
        'modifier': modifier,
        'maneuverType': maneuverType,
        'maneuverLat': maneuverLat,
        'maneuverLng': maneuverLng,
      };

  factory RouteStep.fromJson(Map<String, dynamic> json) => RouteStep(
        instruction: json['instruction'] as String? ?? '',
        distance: (json['distance'] as num).toDouble(),
        duration: (json['duration'] as num).toDouble(),
        modifier: json['modifier'] as String?,
        maneuverType: json['maneuverType'] as String?,
        maneuverLat: (json['maneuverLat'] as num?)?.toDouble(),
        maneuverLng: (json['maneuverLng'] as num?)?.toDouble(),
      );
}

class RouteModel {
  final String id;
  final LocationModel origin;
  final LocationModel destination;
  final List<List<double>> coordinates;
  final double distance;
  final double duration;
  final List<String> congestionLevels;
  final List<RouteStep> steps;
  final double aiScore;
  final String label;

  const RouteModel({
    required this.id,
    required this.origin,
    required this.destination,
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.congestionLevels,
    required this.steps,
    required this.aiScore,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'coordinates': coordinates,
        'distance': distance,
        'duration': duration,
        'congestionLevels': congestionLevels,
        'steps': steps.map((s) => s.toJson()).toList(),
        'aiScore': aiScore,
        'label': label,
      };

  factory RouteModel.fromJson(Map<String, dynamic> json) => RouteModel(
        id: json['id'] as String,
        origin: LocationModel.fromJson(json['origin'] as Map<String, dynamic>),
        destination:
            LocationModel.fromJson(json['destination'] as Map<String, dynamic>),
        coordinates: (json['coordinates'] as List)
            .map<List<double>>(
                (c) => (c as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
        distance: (json['distance'] as num).toDouble(),
        duration: (json['duration'] as num).toDouble(),
        congestionLevels:
            (json['congestionLevels'] as List).map((c) => c.toString()).toList(),
        steps: (json['steps'] as List)
            .map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        aiScore: (json['aiScore'] as num).toDouble(),
        label: json['label'] as String,
      );

  String get distanceText {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toInt()} m';
  }

  String get durationText {
    final minutes = (duration / 60).ceil();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '$minutes min';
  }

  double get congestionScore {
    if (congestionLevels.isEmpty) return 0;
    double score = 0;
    for (final level in congestionLevels) {
      switch (level) {
        case 'low':
          score += 0;
        case 'moderate':
          score += 1;
        case 'heavy':
          score += 3;
        case 'severe':
          score += 5;
        default:
          score += 0;
      }
    }
    return score / congestionLevels.length;
  }
}

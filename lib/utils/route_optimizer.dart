import '../models/route_model.dart';
import '../config/app_config.dart';

class RouteOptimizer {
  static List<RouteModel> scoreAndRank(List<RouteModel> routes) {
    if (routes.isEmpty) return routes;

    double maxDist = 0, maxDur = 0, maxCong = 0;
    for (final r in routes) {
      if (r.distance > maxDist) maxDist = r.distance;
      if (r.duration > maxDur) maxDur = r.duration;
      if (r.congestionScore > maxCong) maxCong = r.congestionScore;
    }
    if (maxDist == 0) maxDist = 1;
    if (maxDur == 0) maxDur = 1;
    if (maxCong == 0) maxCong = 1;

    int bestIdx = 0, shortIdx = 0, clearIdx = 0;
    double bestScore = double.infinity;
    double shortDist = double.infinity;
    double leastCong = double.infinity;

    final scored = <(RouteModel, double)>[];

    for (int i = 0; i < routes.length; i++) {
      final r = routes[i];
      final score =
          (r.distance / maxDist) * AppConfig.weightDistance +
          (r.duration / maxDur) * AppConfig.weightDuration +
          (r.congestionScore / maxCong) * AppConfig.weightCongestion;

      scored.add((r, score));

      if (score < bestScore) { bestScore = score; bestIdx = i; }
      if (r.distance < shortDist) { shortDist = r.distance; shortIdx = i; }
      if (r.congestionScore < leastCong) { leastCong = r.congestionScore; clearIdx = i; }
    }

    final result = <RouteModel>[];
    for (int i = 0; i < scored.length; i++) {
      final (route, score) = scored[i];
      String label;
      if (i == bestIdx) {
        label = 'AI RECOMMENDED';
      } else if (i == shortIdx) {
        label = 'SHORTEST';
      } else if (i == clearIdx) {
        label = 'LEAST TRAFFIC';
      } else {
        label = 'ALTERNATIVE';
      }

      result.add(RouteModel(
        id: route.id,
        origin: route.origin,
        destination: route.destination,
        coordinates: route.coordinates,
        distance: route.distance,
        duration: route.duration,
        congestionLevels: route.congestionLevels,
        steps: route.steps,
        aiScore: score,
        label: label,
      ));
    }

    result.sort((a, b) => a.aiScore.compareTo(b.aiScore));
    return result;
  }
}

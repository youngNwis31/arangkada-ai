import '../ride_logger.dart';
import '../../core/offline/connectivity_monitor.dart';
import '../../models/ride_log_model.dart';

class AiContext {
  final RideLogger rideLogger;
  final ConnectivityMonitor connectivity;

  const AiContext({
    required this.rideLogger,
    required this.connectivity,
  });

  Map<String, String> gather() {
    final now = DateTime.now();
    return {
      'greeting': _buildGreeting(now),
      'earnings_summary': _buildEarningsSummary(),
      'per_ride_average': _buildPerRideAverage(),
      'platform_comparison': _buildPlatformComparison(),
      'fuel_analysis': _buildFuelAnalysis(),
      'time_of_day': _timeOfDay(now),
      'is_online': connectivity.isOnline.toString(),
    };
  }

  String fillTemplate(String template, Map<String, String> context) {
    var result = template;
    for (final entry in context.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  String _buildGreeting(DateTime now) {
    final hour = now.hour;
    final timeGreet = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    final todayRides = rideLogger.todayRideCount;
    final todayEarnings = rideLogger.todayEarnings;

    if (todayRides > 0) {
      return '$timeGreet, rider! You\'ve done $todayRides ride${todayRides == 1 ? '' : 's'} '
          'today with ₱${todayEarnings.toStringAsFixed(0)} in earnings. '
          'How can I help?';
    }
    return '$timeGreet, rider! Ready to hit the road? '
        'Ask me anything — traffic rules, earnings tips, or navigation help!';
  }

  String _buildEarningsSummary() {
    final todayE = rideLogger.todayEarnings;
    final todayR = rideLogger.todayRideCount;
    final weekE = rideLogger.weekEarnings;
    final todayFuel = rideLogger.todayFuelCost;

    if (todayR == 0 && weekE == 0) {
      return 'No rides logged yet. Start tracking in the Rides tab — '
          'select your platform and tap START RIDE when you get a booking. '
          'I\'ll help you analyze your earnings over time!';
    }

    final buf = StringBuffer('Your earnings summary:\n');
    if (todayR > 0) {
      buf.writeln('• Today: ₱${todayE.toStringAsFixed(0)} from $todayR ride${todayR == 1 ? '' : 's'}');
      buf.writeln('• Fuel cost today: ~₱${todayFuel.toStringAsFixed(0)}');
      buf.writeln('• Net today: ₱${(todayE - todayFuel).toStringAsFixed(0)}');
    }
    if (weekE > 0) {
      buf.writeln('• This week: ₱${weekE.toStringAsFixed(0)} gross');
      buf.writeln('• Week fuel: ~₱${rideLogger.weekFuelCost.toStringAsFixed(0)}');
    }
    buf.write('\nTrack more rides to get better insights!');
    return buf.toString();
  }

  String _buildPerRideAverage() {
    final weekLogs = rideLogger.weekLogs;
    if (weekLogs.isEmpty) {
      return 'No rides logged this week yet. Log a few rides and I can '
          'calculate your average per ride, per km, and per hour.';
    }

    final totalEarnings = weekLogs.fold<double>(0, (s, r) => s + r.estimatedEarning);
    final avgPerRide = totalEarnings / weekLogs.length;
    final totalDist = weekLogs.fold<double>(0, (s, r) => s + r.distanceKm);
    final avgPerKm = totalDist > 0 ? totalEarnings / totalDist : 0;

    final byPlatform = <RidePlatform, List<double>>{};
    for (final r in weekLogs) {
      byPlatform.putIfAbsent(r.platform, () => []).add(r.estimatedEarning);
    }

    final buf = StringBuffer('Your per-ride averages (this week):\n');
    buf.writeln('• Overall: ₱${avgPerRide.toStringAsFixed(0)}/ride');
    if (totalDist > 0) {
      buf.writeln('• Per km: ₱${avgPerKm.toStringAsFixed(1)}/km');
    }
    buf.writeln('• Total rides: ${weekLogs.length}');
    for (final entry in byPlatform.entries) {
      final avg = entry.value.fold<double>(0, (s, e) => s + e) / entry.value.length;
      buf.writeln('• ${entry.key.label}: ₱${avg.toStringAsFixed(0)}/ride (${entry.value.length} rides)');
    }
    return buf.toString();
  }

  String _buildPlatformComparison() {
    final earnings = rideLogger.earningsByPlatform;
    if (earnings.isEmpty) {
      return 'Log rides on different platforms and I\'ll compare which one '
          'earns you the most. Tip: try tracking on Grab, FoodPanda, and Angkas '
          'for a week to see the difference!';
    }

    final sorted = earnings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = sorted.first;

    final buf = StringBuffer('Platform earnings this week:\n');
    for (final entry in sorted) {
      buf.writeln('• ${entry.key.label}: ₱${entry.value.toStringAsFixed(0)}');
    }
    buf.write('\n${best.key.emoji} ${best.key.label} is your top earner this week!');
    return buf.toString();
  }

  String _buildFuelAnalysis() {
    final todayFuel = rideLogger.todayFuelCost;
    final todayEarnings = rideLogger.todayEarnings;
    final weekFuel = rideLogger.weekFuelCost;
    final weekEarnings = rideLogger.weekEarnings;

    if (weekEarnings == 0) {
      return 'No rides logged yet. Once you start tracking, I\'ll calculate your '
          'fuel costs and efficiency. Current fuel price setting: '
          '₱${rideLogger.fuelPricePerLiter.toStringAsFixed(0)}/L. '
          'You can update this in Settings.';
    }

    final weekFuelPercent = weekEarnings > 0 ? (weekFuel / weekEarnings * 100) : 0;
    final buf = StringBuffer('Fuel cost analysis:\n');
    if (todayEarnings > 0) {
      final todayPercent = (todayFuel / todayEarnings * 100);
      buf.writeln('• Today: ₱${todayFuel.toStringAsFixed(0)} fuel (${todayPercent.toStringAsFixed(0)}% of earnings)');
    }
    buf.writeln('• This week: ₱${weekFuel.toStringAsFixed(0)} fuel (${weekFuelPercent.toStringAsFixed(0)}% of earnings)');
    buf.writeln('• Fuel price: ₱${rideLogger.fuelPricePerLiter.toStringAsFixed(0)}/L');
    buf.writeln('• Bike efficiency: ${rideLogger.vehicleKmPerLiter.toStringAsFixed(0)} km/L');
    if (weekFuelPercent > 35) {
      buf.write('\n⚠️ Fuel is eating ${weekFuelPercent.toStringAsFixed(0)}% of your income. '
          'Consider fuel-saving tips or more efficient routes.');
    } else {
      buf.write('\n✅ Your fuel costs look reasonable.');
    }
    return buf.toString();
  }

  String _timeOfDay(DateTime now) {
    final h = now.hour;
    if (h >= 6 && h < 9) return 'morning_rush';
    if (h >= 9 && h < 11) return 'mid_morning';
    if (h >= 11 && h < 13) return 'lunch_rush';
    if (h >= 13 && h < 16) return 'afternoon';
    if (h >= 16 && h < 20) return 'evening_rush';
    if (h >= 20 && h < 23) return 'late_evening';
    return 'late_night';
  }
}

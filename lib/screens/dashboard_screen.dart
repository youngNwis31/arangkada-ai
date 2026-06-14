import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/ride_log_model.dart';
import '../services/ride_logger.dart';
import '../widgets/malate_card.dart';
import 'fuel_calculator_screen.dart';
import 'hotspot_screen.dart';
import 'safety_screen.dart';
import 'ai_assistant_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    return Scaffold(
      backgroundColor: c.midnight,
      appBar: AppBar(
        backgroundColor: c.midnight,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MalateColors.neonMint.withValues(alpha: 0.1),
                border: Border.all(
                  color: MalateColors.neonMint.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(Icons.two_wheeler,
                  color: MalateColors.neonMint, size: 18),
            ),
            const SizedBox(width: 10),
            Text('DASHBOARD',
                style: MalateTypography.neonAccent(MalateColors.neonMint)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.textSecondary),
            onPressed: () => context.read<RideLogger>().refreshLogs(),
          ),
        ],
      ),
      body: Consumer<RideLogger>(
        builder: (context, logger, _) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
            children: [
              _todayOverview(context, logger),
              const SizedBox(height: 16),
              _quickActions(context),
              const SizedBox(height: 20),
              _weeklyAnalytics(context, logger),
              const SizedBox(height: 20),
              _platformComparison(context, logger),
              const SizedBox(height: 20),
              _performanceInsights(context, logger),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _todayOverview(BuildContext context, RideLogger logger) {
    final c = MalateColors.of(context);
    final netProfit = logger.todayEarnings - logger.todayFuelCost;
    final isProfit = netProfit >= 0;
    final hours = logger.todayRideDuration.inHours;
    final mins = logger.todayRideDuration.inMinutes % 60;

    return MalateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny, color: MalateColors.electricAmber, size: 18),
              const SizedBox(width: 8),
              Text("TODAY'S PERFORMANCE",
                  style: MalateTypography.neonAccent(MalateColors.electricAmber)
                      .copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statColumn(
                  context,
                  label: 'NET PROFIT',
                  value:
                      '${isProfit ? "+" : ""}₱${netProfit.abs().toStringAsFixed(0)}',
                  color: isProfit
                      ? MalateColors.neonMint
                      : MalateColors.hazardRed,
                  large: true,
                ),
              ),
              Container(
                  width: 1,
                  height: 50,
                  color: c.sidewalk),
              Expanded(
                child: _statColumn(
                  context,
                  label: 'RIDES',
                  value: '${logger.todayRideCount}',
                  color: MalateColors.cyberCyan,
                ),
              ),
              Container(
                  width: 1,
                  height: 50,
                  color: c.sidewalk),
              Expanded(
                child: _statColumn(
                  context,
                  label: 'TIME',
                  value: '${hours}h ${mins}m',
                  color: MalateColors.electricAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.gutter,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(context, 'Gross',
                    '₱${logger.todayEarnings.toStringAsFixed(0)}', c.textSecondary),
                _miniStat(context, 'Fuel',
                    '-₱${logger.todayFuelCost.toStringAsFixed(0)}', MalateColors.hazardRed),
                _miniStat(context, 'Distance',
                    '${logger.todayDistance.toStringAsFixed(1)} km', c.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(BuildContext context,
      {required String label,
      required String value,
      required Color color,
      bool large = false}) {
    return Column(
      children: [
        Text(
          value,
          style: (large
                  ? MalateTypography.headlineLarge
                  : MalateTypography.headlineMedium)
              .copyWith(color: color, fontSize: large ? 26 : 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: MalateTypography.labelSmall.copyWith(
            color: MalateColors.of(context).textMuted,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(
      BuildContext context, String label, String value, Color valueColor) {
    final c = MalateColors.of(context);
    return Column(
      children: [
        Text(value,
            style: MalateTypography.headlineSmall
                .copyWith(fontSize: 13, color: valueColor)),
        Text(label,
            style:
                MalateTypography.labelSmall.copyWith(color: c.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK ACCESS',
            style: MalateTypography.neonAccent(MalateColors.of(context).textMuted)
                .copyWith(fontSize: 11)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                context,
                icon: Icons.local_gas_station,
                label: 'Fuel\nCalculator',
                color: MalateColors.electricAmber,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FuelCalculatorScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                context,
                icon: Icons.map,
                label: 'Booking\nHotspots',
                color: MalateColors.cyberCyan,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HotspotScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                context,
                icon: Icons.shield,
                label: 'Rider\nSafety',
                color: MalateColors.hazardRed,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SafetyScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                context,
                icon: Icons.smart_toy,
                label: 'AI\nAssistant',
                color: MalateColors.neonMint,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    final c = MalateColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: c.asphalt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: MalateTypography.labelSmall.copyWith(
                color: c.textSecondary,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyAnalytics(BuildContext context, RideLogger logger) {
    final c = MalateColors.of(context);
    final weekNet = logger.weekEarnings - logger.weekFuelCost;
    final isProfit = weekNet >= 0;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = logger.weeklyRideCounts;
    final maxCount =
        counts.values.fold(0, (a, b) => a > b ? a : b).clamp(1, 999);

    return MalateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: MalateColors.cyberCyan, size: 18),
              const SizedBox(width: 8),
              Text('THIS WEEK',
                  style: MalateTypography.neonAccent(MalateColors.cyberCyan)
                      .copyWith(fontSize: 11)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isProfit ? MalateColors.neonMint : MalateColors.hazardRed)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isProfit ? "+" : ""}₱${weekNet.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isProfit
                        ? MalateColors.neonMint
                        : MalateColors.hazardRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _weekStat(context, 'Earnings',
                  '₱${logger.weekEarnings.toStringAsFixed(0)}', MalateColors.neonMint),
              _weekStat(context, 'Fuel Cost',
                  '₱${logger.weekFuelCost.toStringAsFixed(0)}', MalateColors.hazardRed),
              _weekStat(context, 'Distance',
                  '${logger.weekDistance.toStringAsFixed(1)}km', MalateColors.cyberCyan),
              _weekStat(context, 'Rides', '${logger.weekLogs.length}',
                  MalateColors.electricAmber),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = i + 1;
                final count = counts[day] ?? 0;
                final ratio = count / maxCount;
                final isToday = DateTime.now().weekday == day;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (count > 0)
                          Text('$count',
                              style: MalateTypography.labelSmall.copyWith(
                                  color: c.textMuted, fontSize: 9)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: (ratio * 44).clamp(4, 44),
                          decoration: BoxDecoration(
                            color: isToday
                                ? MalateColors.neonMint
                                : MalateColors.cyberCyan.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i],
                          style: MalateTypography.labelSmall.copyWith(
                            color: isToday
                                ? MalateColors.neonMint
                                : c.textMuted,
                            fontSize: 9,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekStat(
      BuildContext context, String label, String value, Color color) {
    final c = MalateColors.of(context);
    return Column(
      children: [
        Text(value,
            style: MalateTypography.headlineSmall
                .copyWith(fontSize: 14, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: MalateTypography.labelSmall
                .copyWith(color: c.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _platformComparison(BuildContext context, RideLogger logger) {
    final c = MalateColors.of(context);
    final platforms = logger.earningsByPlatform;
    if (platforms.isEmpty) {
      return MalateCard(
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline, color: c.textDisabled, size: 32),
            const SizedBox(height: 8),
            Text('No ride data yet',
                style: MalateTypography.bodySmall.copyWith(color: c.textMuted)),
            const SizedBox(height: 4),
            Text('Start logging rides to see platform comparison',
                style: MalateTypography.labelSmall
                    .copyWith(color: c.textDisabled, fontSize: 10)),
          ],
        ),
      );
    }

    final totalEarnings =
        platforms.values.fold(0.0, (sum, v) => sum + v).clamp(1.0, double.infinity);
    final sorted = platforms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final platformColors = <RidePlatform, Color>{
      RidePlatform.grab: const Color(0xFF00B14F),
      RidePlatform.foodPanda: const Color(0xFFD70F64),
      RidePlatform.moveIt: const Color(0xFF1DA1F2),
      RidePlatform.angkas: const Color(0xFFFF6B00),
      RidePlatform.joyRide: const Color(0xFF8B5CF6),
      RidePlatform.lalamove: const Color(0xFFFF8C00),
      RidePlatform.other: MalateColors.cyberCyan,
    };

    return MalateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows,
                  color: MalateColors.neonMint, size: 18),
              const SizedBox(width: 8),
              Text('PLATFORM EARNINGS',
                  style: MalateTypography.neonAccent(MalateColors.neonMint)
                      .copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          ...sorted.map((e) {
            final pct = (e.value / totalEarnings * 100);
            final color = platformColors[e.key] ?? MalateColors.cyberCyan;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.name.toUpperCase(),
                          style: MalateTypography.labelMedium
                              .copyWith(color: color, fontSize: 12)),
                      Text(
                          '₱${e.value.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)',
                          style: MalateTypography.labelSmall
                              .copyWith(color: c.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: e.value / totalEarnings,
                      backgroundColor: c.gutter,
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _performanceInsights(BuildContext context, RideLogger logger) {
    final c = MalateColors.of(context);
    final allRides = logger.allLogs;
    if (allRides.isEmpty) {
      return MalateCard(
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline, color: c.textDisabled, size: 32),
            const SizedBox(height: 8),
            Text('Insights will appear here',
                style: MalateTypography.bodySmall.copyWith(color: c.textMuted)),
            const SizedBox(height: 4),
            Text('Keep logging rides to unlock performance insights',
                style: MalateTypography.labelSmall
                    .copyWith(color: c.textDisabled, fontSize: 10)),
          ],
        ),
      );
    }

    final totalEarnings = allRides.fold(0.0, (s, r) => s + r.estimatedEarning);
    final totalFuel = allRides.fold(0.0, (s, r) => s + r.fuelCost);
    final totalKm = allRides.fold(0.0, (s, r) => s + r.distanceKm);
    final avgPerRide =
        allRides.isEmpty ? 0.0 : totalEarnings / allRides.length;
    final avgPerKm = totalKm > 0 ? totalEarnings / totalKm : 0.0;
    final profitMargin =
        totalEarnings > 0 ? (totalEarnings - totalFuel) / totalEarnings * 100 : 0.0;

    final bestHour = _findBestHour(allRides);
    final bestDay = _findBestDay(allRides);

    return MalateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb,
                  color: MalateColors.electricAmber, size: 18),
              const SizedBox(width: 8),
              Text('RIDER INSIGHTS',
                  style:
                      MalateTypography.neonAccent(MalateColors.electricAmber)
                          .copyWith(fontSize: 11)),
              const Spacer(),
              Text('${allRides.length} rides total',
                  style: MalateTypography.labelSmall
                      .copyWith(color: c.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 14),
          _insightRow(context, Icons.attach_money, 'Avg per Ride',
              '₱${avgPerRide.toStringAsFixed(0)}', MalateColors.neonMint),
          _insightRow(context, Icons.speed, 'Avg per KM',
              '₱${avgPerKm.toStringAsFixed(1)}/km', MalateColors.cyberCyan),
          _insightRow(
              context,
              Icons.pie_chart,
              'Profit Margin',
              '${profitMargin.toStringAsFixed(0)}%',
              profitMargin >= 70
                  ? MalateColors.neonMint
                  : profitMargin >= 50
                      ? MalateColors.electricAmber
                      : MalateColors.hazardRed),
          if (bestHour != null)
            _insightRow(context, Icons.access_time, 'Best Time', bestHour,
                MalateColors.electricAmber),
          if (bestDay != null)
            _insightRow(context, Icons.calendar_today, 'Best Day', bestDay,
                MalateColors.cyberCyan),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MalateColors.neonMint.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: MalateColors.neonMint.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _generateTip(profitMargin, bestHour, bestDay),
                    style: MalateTypography.bodySmall.copyWith(
                      color: c.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightRow(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(label, style: MalateTypography.bodySmall),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      ),
    );
  }

  String? _findBestHour(List<RideLog> rides) {
    if (rides.length < 3) return null;
    final hourCounts = <int, int>{};
    for (final r in rides) {
      final h = r.startTime.hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }
    final best = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final h = best.first.key;
    final period = h >= 12 ? 'PM' : 'AM';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$display:00 $period';
  }

  String? _findBestDay(List<RideLog> rides) {
    if (rides.length < 5) return null;
    final dayCounts = <int, int>{};
    for (final r in rides) {
      final d = r.startTime.weekday;
      dayCounts[d] = (dayCounts[d] ?? 0) + 1;
    }
    final best = dayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayNames[best.first.key];
  }

  String _generateTip(double margin, String? bestHour, String? bestDay) {
    if (margin < 50) {
      return 'Medyo mataas ang fuel cost mo. Try shorter routes or check tire pressure para mag-improve ang km/L.';
    }
    if (bestHour != null && bestDay != null) {
      return 'Peak performance mo: $bestDay around $bestHour. Focus dyan para mas malaki ang kita!';
    }
    if (margin >= 70) {
      return 'Maganda ang profit margin mo! Keep it up, rider. Consistency is key.';
    }
    return 'Keep logging rides para ma-unlock ang personalized insights mo.';
  }
}

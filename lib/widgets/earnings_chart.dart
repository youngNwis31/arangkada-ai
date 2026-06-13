import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';

class EarningsWeeklyChart extends StatelessWidget {
  final Map<int, int> rideCounts;

  const EarningsWeeklyChart({super.key, required this.rideCounts});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    final maxY = rideCounts.values.fold(0, (a, b) => a > b ? a : b);
    final topY = (maxY + 2).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: c.gutter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.sidewalk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIS WEEK',
              style: MalateTypography.neonAccent(MalateColors.electricAmber)
                  .copyWith(fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: topY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i < 0 || i >= 7) return const SizedBox.shrink();
                        final isToday = DateTime.now().weekday == i + 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _dayLabels[i],
                            style: MalateTypography.labelSmall.copyWith(
                              color: isToday
                                  ? MalateColors.neonMint
                                  : c.textMuted,
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final count = (rideCounts[i + 1] ?? 0).toDouble();
                  final isToday = DateTime.now().weekday == i + 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                        color: isToday
                            ? MalateColors.neonMint
                            : MalateColors.neonMint.withValues(alpha: 0.3),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

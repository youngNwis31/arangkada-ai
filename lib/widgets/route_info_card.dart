import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/route_model.dart';
import 'neon_badge.dart';

class RouteInfoCard extends StatelessWidget {
  final List<RouteModel> routes;
  final int selectedIndex;
  final ValueChanged<int> onRouteSelected;

  const RouteInfoCard({
    super.key,
    required this.routes,
    required this.selectedIndex,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MalateColors.asphalt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: MalateColors.sidewalk),
          left: BorderSide(color: MalateColors.sidewalk),
          right: BorderSide(color: MalateColors.sidewalk),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MalateColors.concrete,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: MalateColors.electricAmber, size: 18),
                  const SizedBox(width: 8),
                  Text('AI ROUTE ANALYSIS',
                      style: MalateTypography.neonAccent(
                          MalateColors.electricAmber)),
                  const Spacer(),
                  Text(
                    '${routes.length} routes',
                    style: MalateTypography.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: routes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _buildRouteCard(i),
                ),
              ),
              if (routes.isNotEmpty && selectedIndex < routes.length) ...[
                const SizedBox(height: 12),
                _buildSteps(routes[selectedIndex]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(int index) {
    final route = routes[index];
    final isSelected = index == selectedIndex;
    final isAi = route.label == 'AI RECOMMENDED';

    return GestureDetector(
      onTap: () => onRouteSelected(index),
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? MalateColors.gutter : MalateColors.midnight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? MalateColors.neonMint : MalateColors.sidewalk,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow:
              isSelected ? MalateColors.subtleGlow(MalateColors.neonMint) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAi) NeonBadge.aiRecommended() else NeonBadge(label: route.label),
            const Spacer(),
            Text(
              route.durationText,
              style: MalateTypography.displayMedium.copyWith(
                fontSize: 22,
                color: isSelected
                    ? MalateColors.neonMint
                    : MalateColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(route.distanceText, style: MalateTypography.bodySmall),
            const SizedBox(height: 6),
            _congestionDot(route),
          ],
        ),
      ),
    );
  }

  Widget _congestionDot(RouteModel route) {
    final score = route.congestionScore;
    final (color, text) = score < 1
        ? (MalateColors.trafficClear, 'CLEAR')
        : score < 2
            ? (MalateColors.trafficModerate, 'MODERATE')
            : (MalateColors.trafficHeavy, 'HEAVY');

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: MalateTypography.labelSmall.copyWith(color: color)),
      ],
    );
  }

  Widget _buildSteps(RouteModel route) {
    final steps = route.steps.where((s) => s.instruction.isNotEmpty).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MalateColors.midnight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MalateColors.sidewalk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DIRECTIONS',
              style: MalateTypography.neonAccent(MalateColors.cyberCyan)
                  .copyWith(fontSize: 11)),
          const SizedBox(height: 8),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(_dirIcon(s.modifier),
                        size: 16, color: MalateColors.cyberCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.instruction,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MalateTypography.bodySmall
                            .copyWith(color: MalateColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )),
          if (route.steps.length > 3)
            Text(
              '+ ${route.steps.length - 3} more steps',
              style: MalateTypography.labelSmall,
            ),
        ],
      ),
    );
  }

  IconData _dirIcon(String? mod) => switch (mod) {
        'left' || 'sharp left' || 'slight left' => Icons.turn_left,
        'right' || 'sharp right' || 'slight right' => Icons.turn_right,
        'uturn' => Icons.u_turn_left,
        'straight' => Icons.straight,
        _ => Icons.navigation,
      };
}

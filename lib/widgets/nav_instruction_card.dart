import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../services/offline_nav_engine.dart';

class NavInstructionCard extends StatelessWidget {
  final OfflineNavEngine engine;

  const NavInstructionCard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final step = engine.currentStep;
    if (step == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MalateColors.asphalt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: engine.state == NavState.offRoute
              ? MalateColors.hazardRed.withValues(alpha: 0.6)
              : MalateColors.neonMint.withValues(alpha: 0.3),
        ),
        boxShadow: engine.state == NavState.offRoute
            ? MalateColors.neonGlow(MalateColors.hazardRed, intensity: 0.3)
            : MalateColors.subtleGlow(MalateColors.neonMint),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (engine.state == NavState.offRoute)
            _offRouteBanner()
          else
            _stepRow(step),
          const SizedBox(height: 16),
          _statsRow(),
          if (engine.nextStep != null) ...[
            const SizedBox(height: 12),
            _nextStepHint(),
          ],
        ],
      ),
    );
  }

  Widget _offRouteBanner() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: MalateColors.hazardRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.wrong_location,
              color: MalateColors.hazardRed, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OFF ROUTE',
                style: MalateTypography.neonAccent(MalateColors.hazardRed),
              ),
              const SizedBox(height: 4),
              Text(
                'Bumalik sa route, rider!',
                style: MalateTypography.bodyMedium
                    .copyWith(color: MalateColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepRow(step) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: MalateColors.neonMint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _maneuverIcon(step.modifier, step.maneuverType),
            color: MalateColors.neonMint,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                engine.distanceToNextText,
                style: MalateTypography.displayMedium.copyWith(
                  fontSize: 28,
                  color: MalateColors.neonMint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.instruction,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: MalateTypography.bodyMedium
                    .copyWith(color: MalateColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statsRow() {
    final remainDist = engine.totalRemainingDistance;
    final distText = remainDist >= 1000
        ? '${(remainDist / 1000).toStringAsFixed(1)} km'
        : '${remainDist.toInt()} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: MalateColors.midnight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(Icons.schedule, engine.etaText, 'ETA'),
          Container(width: 1, height: 24, color: MalateColors.sidewalk),
          _stat(Icons.straighten, distText, 'LEFT'),
          Container(width: 1, height: 24, color: MalateColors.sidewalk),
          _stat(Icons.speed, '${(engine.speedMs * 3.6).toInt()} km/h', 'SPEED'),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: MalateColors.cyberCyan, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: MalateTypography.headlineSmall
                  .copyWith(fontSize: 15, color: MalateColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: MalateTypography.labelSmall),
      ],
    );
  }

  Widget _nextStepHint() {
    final next = engine.nextStep!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MalateColors.gutter,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('THEN ', style: MalateTypography.labelSmall),
          Icon(
            _maneuverIcon(next.modifier, next.maneuverType),
            color: MalateColors.textMuted,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              next.instruction,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MalateTypography.bodySmall
                  .copyWith(color: MalateColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  IconData _maneuverIcon(String? modifier, String? type) {
    if (type == 'arrive') return Icons.flag;
    if (type == 'depart') return Icons.navigation;
    if (type == 'roundabout' || type == 'rotary') return Icons.roundabout_right;
    return switch (modifier) {
      'left' || 'sharp left' || 'slight left' => Icons.turn_left,
      'right' || 'sharp right' || 'slight right' => Icons.turn_right,
      'uturn' => Icons.u_turn_left,
      'straight' => Icons.straight,
      _ => Icons.navigation,
    };
  }
}

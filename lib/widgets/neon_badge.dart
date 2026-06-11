import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';

class NeonBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const NeonBadge({
    super.key,
    required this.label,
    this.color = MalateColors.neonMint,
    this.icon,
  });

  factory NeonBadge.aiRecommended() => const NeonBadge(
        label: 'AI PICK',
        color: MalateColors.electricAmber,
        icon: Icons.auto_awesome,
      );

  factory NeonBadge.offline() => const NeonBadge(
        label: 'OFFLINE',
        color: MalateColors.hazardRed,
        icon: Icons.cloud_off,
      );

  factory NeonBadge.online() => const NeonBadge(
        label: 'ONLINE',
        color: MalateColors.neonMint,
        icon: Icons.cloud_done,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

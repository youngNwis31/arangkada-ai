import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../models/hazard_report.dart';

class FloodMarker extends StatelessWidget {
  final HazardReport report;
  const FloodMarker({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final severity = report.type.floodSeverity;
    final color = _severityColor(severity);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: severity >= 3 ? 10 : 6,
            spreadRadius: severity >= 3 ? 2 : 0,
          ),
        ],
      ),
      child: Icon(Icons.water_drop, color: color, size: 18),
    );
  }

  static Color _severityColor(int severity) => switch (severity) {
        1 => MalateColors.cyberCyan,
        2 => const Color(0xFF2196F3),
        _ => const Color(0xFF1565C0),
      };
}

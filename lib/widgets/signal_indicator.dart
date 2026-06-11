import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../core/offline/connectivity_monitor.dart';

class SignalIndicator extends StatelessWidget {
  final ConnectivityMonitor connectivity;

  const SignalIndicator({super.key, required this.connectivity});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) {
        final isOnline = connectivity.isOnline;
        final color = isOnline ? MalateColors.neonMint : MalateColors.hazardRed;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: MalateColors.subtleGlow(color),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                connectivity.statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

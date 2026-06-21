import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../services/crash_detector.dart';

class CrashAlertOverlay extends StatelessWidget {
  const CrashAlertOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final detector = context.watch<CrashDetector>();
    if (!detector.isActive) return const SizedBox.shrink();

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CRASH DETECTED',
                style: MalateTypography.headlineLarge.copyWith(
                  color: MalateColors.hazardRed,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),
              _PulsingCountdown(seconds: detector.secondsRemaining),
              const SizedBox(height: 24),
              Text(
                detector.state == CrashState.sosTriggered
                    ? 'SOS SENT'
                    : 'SOS in ${detector.secondsRemaining}s',
                style: MalateTypography.headlineSmall.copyWith(
                  color: MalateColors.hazardRed,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap below if you\'re OK',
                style: MalateTypography.bodyMedium.copyWith(
                  color: MalateColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              if (detector.state == CrashState.countdown)
                GestureDetector(
                  onTap: detector.dismiss,
                  child: Container(
                    width: 200,
                    height: 64,
                    decoration: BoxDecoration(
                      color: MalateColors.neonMint,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: MalateColors.neonGlow(
                        MalateColors.neonMint,
                        intensity: 0.6,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "I'M OK",
                        style: MalateTypography.headlineSmall.copyWith(
                          color: MalateColors.midnight,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingCountdown extends StatefulWidget {
  final int seconds;
  const _PulsingCountdown({required this.seconds});

  @override
  State<_PulsingCountdown> createState() => _PulsingCountdownState();
}

class _PulsingCountdownState extends State<_PulsingCountdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MalateColors.hazardRed,
              boxShadow: MalateColors.neonGlow(
                MalateColors.hazardRed,
                intensity: 0.7,
              ),
            ),
            child: Center(
              child: Text(
                '${widget.seconds}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

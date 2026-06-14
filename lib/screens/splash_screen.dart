import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../config/app_config.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)),
    );

    _glowPulse = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.5, 1.0, curve: Curves.easeInOut)),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    return Scaffold(
      backgroundColor: c.midnight,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _fadeIn.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MalateColors.neonMint
                          .withValues(alpha: 0.1),
                      border: Border.all(
                        color: MalateColors.neonMint
                            .withValues(alpha: _glowPulse.value),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MalateColors.neonMint
                              .withValues(alpha: _glowPulse.value * 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.two_wheeler,
                      size: 48,
                      color: MalateColors.neonMint,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppConfig.appName.toUpperCase(),
                    style: MalateTypography.headlineLarge.copyWith(
                      letterSpacing: 4,
                      color: MalateColors.neonMint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConfig.appTagline.toUpperCase(),
                    style: MalateTypography.labelSmall.copyWith(
                      letterSpacing: 2,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MalateColors.neonMint
                          .withValues(alpha: _glowPulse.value),
                    ),
                  ),
                  const SizedBox(height: 80),
                  Text(
                    AppConfig.appVersion,
                    style: MalateTypography.labelSmall.copyWith(
                      color: c.textDisabled,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

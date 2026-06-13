import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';

class MalateCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final List<BoxShadow>? glow;
  final VoidCallback? onTap;

  const MalateCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.glow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? c.asphalt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor ?? c.sidewalk,
            width: 1,
          ),
          boxShadow: glow,
        ),
        child: child,
      ),
    );
  }
}

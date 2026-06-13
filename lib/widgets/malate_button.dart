import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';

class MalateButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool outlined;
  final bool compact;

  const MalateButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.outlined = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? MalateColors.neonMint;
    final height = compact ? 44.0 : 56.0;

    if (outlined) {
      return SizedBox(
        height: height,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: btnColor,
            side: BorderSide(color: btnColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: MalateTypography.labelLarge.copyWith(color: btnColor),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: MalateColors.of(context).midnight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: MalateTypography.labelLarge,
          elevation: 0,
        ),
      ),
    );
  }
}

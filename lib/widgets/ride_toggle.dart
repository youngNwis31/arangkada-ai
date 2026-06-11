import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/ride_log_model.dart';
import '../services/ride_logger.dart';

class RideToggle extends StatelessWidget {
  const RideToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RideLogger>(
      builder: (context, logger, _) {
        if (logger.isRiding) return _activeRideCard(context, logger);
        return _startRideCard(context, logger);
      },
    );
  }

  Widget _startRideCard(BuildContext context, RideLogger logger) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MalateColors.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MalateColors.sidewalk),
      ),
      child: Row(
        children: [
          _platformSelector(context, logger),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => logger.startRide(),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: Text('START RIDE',
                    style: MalateTypography.labelLarge
                        .copyWith(color: MalateColors.midnight, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MalateColors.neonMint,
                  foregroundColor: MalateColors.midnight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeRideCard(BuildContext context, RideLogger logger) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MalateColors.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MalateColors.neonMint.withValues(alpha: 0.4)),
        boxShadow: MalateColors.subtleGlow(MalateColors.neonMint),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MalateColors.neonMint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.two_wheeler,
                color: MalateColors.neonMint, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RIDING — ${logger.selectedPlatform.label}',
                  style: MalateTypography.labelSmall
                      .copyWith(color: MalateColors.neonMint),
                ),
                const SizedBox(height: 2),
                _RideTimer(startTime: logger.activeRide!.startTime),
              ],
            ),
          ),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: () => _showEndRideDialog(context, logger),
              style: ElevatedButton.styleFrom(
                backgroundColor: MalateColors.hazardRed,
                foregroundColor: MalateColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('END',
                  style: MalateTypography.labelLarge.copyWith(
                      color: MalateColors.textPrimary, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _platformSelector(BuildContext context, RideLogger logger) {
    return GestureDetector(
      onTap: () => _showPlatformPicker(context, logger),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: MalateColors.gutter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MalateColors.concrete),
        ),
        child: Center(
          child: Text(logger.selectedPlatform.emoji,
              style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  void _showPlatformPicker(BuildContext context, RideLogger logger) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MalateColors.asphalt,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELECT PLATFORM',
                style: MalateTypography.neonAccent(MalateColors.electricAmber)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: RidePlatform.values.map((p) {
                final selected = p == logger.selectedPlatform;
                return GestureDetector(
                  onTap: () {
                    logger.selectPlatform(p);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? MalateColors.neonMint.withValues(alpha: 0.1)
                          : MalateColors.gutter,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? MalateColors.neonMint
                            : MalateColors.sidewalk,
                      ),
                    ),
                    child: Text(
                      '${p.emoji} ${p.label}',
                      style: MalateTypography.bodyMedium.copyWith(
                        color: selected
                            ? MalateColors.neonMint
                            : MalateColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEndRideDialog(BuildContext context, RideLogger logger) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MalateColors.asphalt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('End Ride',
            style: MalateTypography.headlineMedium
                .copyWith(color: MalateColors.neonMint)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Magkano kinita mo sa ride na ito?',
                style: MalateTypography.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: MalateTypography.headlineLarge
                  .copyWith(color: MalateColors.neonMint, fontSize: 28),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: MalateTypography.headlineLarge.copyWith(
                    color: MalateColors.neonMint.withValues(alpha: 0.5),
                    fontSize: 28),
                hintText: '0',
                hintStyle: MalateTypography.headlineLarge.copyWith(
                    color: MalateColors.textDisabled, fontSize: 28),
                filled: true,
                fillColor: MalateColors.gutter,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL',
                style: TextStyle(color: MalateColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final earning =
                  double.tryParse(controller.text) ?? 0;
              logger.endRide(earning: earning);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MalateColors.neonMint,
              foregroundColor: MalateColors.midnight,
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

class _RideTimer extends StatefulWidget {
  final DateTime startTime;
  const _RideTimer({required this.startTime});

  @override
  State<_RideTimer> createState() => _RideTimerState();
}

class _RideTimerState extends State<_RideTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dur = DateTime.now().difference(widget.startTime);
    final h = dur.inHours.toString().padLeft(2, '0');
    final m = (dur.inMinutes % 60).toString().padLeft(2, '0');
    final s = (dur.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$h:$m:$s',
      style: MalateTypography.headlineSmall
          .copyWith(color: MalateColors.textPrimary, fontFeatures: [
        const FontFeature.tabularFigures(),
      ]),
    );
  }
}

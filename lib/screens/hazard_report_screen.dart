import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/hazard_report.dart';
import '../models/location_model.dart';
import '../services/hazard_service.dart';
import '../widgets/malate_card.dart';

class HazardReportScreen extends StatefulWidget {
  final LocationModel? currentLocation;
  const HazardReportScreen({super.key, this.currentLocation});

  @override
  State<HazardReportScreen> createState() => _HazardReportScreenState();
}

class _HazardReportScreenState extends State<HazardReportScreen> {
  HazardType? _selected;
  bool _submitting = false;

  final _hazardOptions = [
    (HazardType.pothole, Icons.dangerous, MalateColors.electricAmber),
    (HazardType.flooding, Icons.water, MalateColors.cyberCyan),
    (HazardType.checkpoint, Icons.local_police, MalateColors.neonMint),
    (HazardType.accident, Icons.car_crash, MalateColors.hazardRed),
    (HazardType.roadClosure, Icons.block, MalateColors.hazardRed),
    (HazardType.construction, Icons.construction, MalateColors.electricAmber),
  ];

  Future<void> _submit() async {
    if (_selected == null || widget.currentLocation == null) return;
    setState(() => _submitting = true);

    await HazardService.reportHazard(
      type: _selected!,
      latitude: widget.currentLocation!.latitude,
      longitude: widget.currentLocation!.longitude,
    );

    if (mounted) {
      final c = MalateColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: MalateColors.neonMint, size: 18),
              const SizedBox(width: 8),
              Text(
                '${_selected!.tagalog} reported — salamat, rider!',
                style: MalateTypography.bodyMedium
                    .copyWith(color: c.textPrimary),
              ),
            ],
          ),
          backgroundColor: c.gutter,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    return Scaffold(
      backgroundColor: c.midnight,
      appBar: AppBar(
        backgroundColor: c.midnight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('REPORT HAZARD',
            style: MalateTypography.neonAccent(MalateColors.electricAmber)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What did you see?', style: MalateTypography.headlineMedium),
            const SizedBox(height: 4),
            Text('One-tap report — saves offline, syncs when back online.',
                style: MalateTypography.bodySmall),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: _hazardOptions.map((opt) {
                  final (type, icon, color) = opt;
                  final isSelected = _selected == type;

                  return MalateCard(
                    onTap: () => setState(() => _selected = type),
                    borderColor: isSelected ? color : null,
                    backgroundColor:
                        isSelected ? color.withValues(alpha: 0.08) : null,
                    glow: isSelected ? MalateColors.subtleGlow(color) : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: color, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          type.tagalog,
                          style: MalateTypography.labelMedium.copyWith(
                            color: isSelected ? color : c.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          type.english,
                          style: MalateTypography.labelSmall.copyWith(
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selected != null && !_submitting ? _submit : null,
                icon: _submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: c.midnight),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(
                  _submitting ? 'REPORTING...' : 'REPORT NOW',
                  style: MalateTypography.labelLarge,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selected != null
                      ? MalateColors.electricAmber
                      : c.concrete,
                  foregroundColor: c.midnight,
                  disabledBackgroundColor: c.concrete,
                  disabledForegroundColor: c.textDisabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

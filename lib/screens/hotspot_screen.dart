import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/ride_log_model.dart';
import '../services/ride_logger.dart';
import '../widgets/malate_card.dart';

enum _TimeSlot {
  morning('Morning (6–10)', 6, 10),
  midday('Midday (10–2)', 10, 14),
  afternoon('Afternoon (2–6)', 14, 18),
  evening('Evening (6–10)', 18, 22),
  night('Night (10–6)', 22, 6);

  final String label;
  final int startHour;
  final int endHour;
  const _TimeSlot(this.label, this.startHour, this.endHour);

  bool contains(int hour) {
    if (startHour < endHour) {
      return hour >= startHour && hour < endHour;
    }
    return hour >= startHour || hour < endHour;
  }
}

class _HotspotArea {
  final String name;
  final int rideCount;
  final double avgEarning;
  final double gridLat;
  final double gridLng;

  const _HotspotArea({
    required this.name,
    required this.rideCount,
    required this.avgEarning,
    required this.gridLat,
    required this.gridLng,
  });
}

class HotspotScreen extends StatefulWidget {
  const HotspotScreen({super.key});

  @override
  State<HotspotScreen> createState() => _HotspotScreenState();
}

class _HotspotScreenState extends State<HotspotScreen> {
  _TimeSlot _selectedSlot = _TimeSlot.morning;
  final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7};

  static const List<String> _dayLabels = [
    '',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  List<RideLog> _filteredRides(List<RideLog> all) {
    return all.where((r) {
      final hour = r.startTime.hour;
      final dow = r.startTime.weekday;
      return _selectedSlot.contains(hour) && _selectedDays.contains(dow);
    }).toList();
  }

  List<_HotspotArea> _computeHotspots(List<RideLog> rides) {
    final cells = <String, List<RideLog>>{};
    for (final r in rides) {
      if (r.originLat == null || r.originLng == null) continue;
      final gridLat = (r.originLat! / 0.01).floor() * 0.01;
      final gridLng = (r.originLng! / 0.01).floor() * 0.01;
      final key = '${gridLat.toStringAsFixed(2)},${gridLng.toStringAsFixed(2)}';
      cells.putIfAbsent(key, () => []).add(r);
    }

    final areas = cells.entries.map((e) {
      final parts = e.key.split(',');
      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);
      final centLat = lat + 0.005;
      final centLng = lng + 0.005;
      final name = _labelForCoords(centLat, centLng);
      final count = e.value.length;
      final avgEarning = count > 0
          ? e.value.fold(0.0, (s, r) => s + r.estimatedEarning) / count
          : 0.0;
      return _HotspotArea(
        name: name,
        rideCount: count,
        avgEarning: avgEarning,
        gridLat: centLat,
        gridLng: centLng,
      );
    }).toList();

    areas.sort((a, b) => b.rideCount.compareTo(a.rideCount));
    return areas;
  }

  String _labelForCoords(double lat, double lng) {
    const knownAreas = <_AreaRef>[
      _AreaRef('Malate', 14.566, 120.989),
      _AreaRef('Ermita', 14.578, 120.985),
      _AreaRef('Intramuros', 14.590, 120.975),
      _AreaRef('Binondo', 14.599, 120.976),
      _AreaRef('Quiapo', 14.599, 120.983),
      _AreaRef('Sampaloc', 14.610, 121.003),
      _AreaRef('Sta. Mesa', 14.601, 121.010),
      _AreaRef('Paco', 14.574, 120.994),
      _AreaRef('Pandacan', 14.587, 121.003),
      _AreaRef('Tondo', 14.614, 120.965),
      _AreaRef('Makati CBD', 14.554, 121.017),
      _AreaRef('BGC', 14.549, 121.050),
      _AreaRef('Mandaluyong', 14.578, 121.035),
      _AreaRef('Pasay', 14.538, 120.996),
      _AreaRef('Parañaque', 14.481, 121.016),
      _AreaRef('Las Piñas', 14.450, 120.983),
      _AreaRef('Pasig', 14.563, 121.067),
      _AreaRef('Marikina', 14.630, 121.102),
      _AreaRef('Quezon City', 14.676, 121.044),
      _AreaRef('Caloocan', 14.651, 120.967),
      _AreaRef('Malabon', 14.663, 120.957),
      _AreaRef('Navotas', 14.660, 120.943),
      _AreaRef('Valenzuela', 14.700, 120.983),
      _AreaRef('NAIA', 14.511, 121.020),
      _AreaRef('MOA Complex', 14.535, 121.002),
    ];

    double minDist = double.infinity;
    String closest = 'Area near ${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}';

    for (final area in knownAreas) {
      final dLat = lat - area.lat;
      final dLng = lng - area.lng;
      final d = sqrt(dLat * dLat + dLng * dLng);
      if (d < minDist) {
        minDist = d;
        closest = minDist < 0.05 ? area.name : 'Near ${area.name}';
      }
    }
    return closest;
  }

  String _formatPeso(double amount) {
    if (amount >= 1000) {
      final thousands = amount / 1000;
      return '₱${thousands.toStringAsFixed(1)}k';
    }
    return '₱${amount.toStringAsFixed(0)}';
  }

  Color _slotColor(_TimeSlot slot) {
    switch (slot) {
      case _TimeSlot.morning:
        return MalateColors.electricAmber;
      case _TimeSlot.midday:
        return MalateColors.cyberCyan;
      case _TimeSlot.afternoon:
        return MalateColors.neonMint;
      case _TimeSlot.evening:
        return MalateColors.electricAmber;
      case _TimeSlot.night:
        return MalateColors.hazardRed;
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
        title: Text(
          'HOTSPOTS',
          style: MalateTypography.neonAccent(MalateColors.neonMint),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.textSecondary),
            onPressed: () => context.read<RideLogger>().refreshLogs(),
          ),
        ],
      ),
      body: Consumer<RideLogger>(
        builder: (context, logger, _) {
          final filtered = _filteredRides(logger.weekLogs);
          final hotspots = _computeHotspots(filtered);
          final maxCount =
              hotspots.isNotEmpty ? hotspots.first.rideCount.toDouble() : 1.0;
          final bestArea = hotspots.isNotEmpty ? hotspots.first.name : '—';
          final accentColor = _slotColor(_selectedSlot);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _summaryCard(context, logger.weekLogs.length, bestArea, accentColor),
              const SizedBox(height: 16),
              _timeSlotSelector(context, accentColor),
              const SizedBox(height: 12),
              _dayFilter(context),
              const SizedBox(height: 16),
              _hotspotList(context, hotspots, maxCount, accentColor),
              const SizedBox(height: 16),
              _infoCard(context),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(
      BuildContext context, int totalRides, String bestArea, Color accent) {
    final c = MalateColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: MalateColors.subtleGlow(accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: accent, size: 16),
              const SizedBox(width: 6),
              Text('RIDE HOTSPOTS',
                  style: MalateTypography.neonAccent(accent)
                      .copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox(
                context,
                label: 'RIDES ANALYZED',
                value: '$totalRides',
                color: MalateColors.cyberCyan,
              ),
              const SizedBox(width: 12),
              _statBox(
                context,
                label: 'TOP SPOT',
                value: bestArea,
                color: MalateColors.neonMint,
                compact: true,
              ),
              const SizedBox(width: 12),
              _statBox(
                context,
                label: 'BEST TIME',
                value: _selectedSlot.label.split(' ').first,
                color: MalateColors.electricAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(BuildContext context,
      {required String label,
      required String value,
      required Color color,
      bool compact = false}) {
    final c = MalateColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: c.midnight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: compact
                  ? MalateTypography.bodySmall
                      .copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 11)
                  : MalateTypography.headlineLarge.copyWith(color: color),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(label,
                style: MalateTypography.labelSmall
                    .copyWith(color: c.textMuted, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _timeSlotSelector(BuildContext context, Color accent) {
    final c = MalateColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIME OF DAY',
            style: MalateTypography.labelSmall.copyWith(color: c.textMuted)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _TimeSlot.values.map((slot) {
              final isActive = slot == _selectedSlot;
              final slotAccent = _slotColor(slot);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSlot = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? slotAccent.withValues(alpha: 0.15)
                          : c.asphalt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? slotAccent
                            : c.sidewalk,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      slot.label,
                      style: MalateTypography.bodySmall.copyWith(
                        color: isActive ? slotAccent : c.textSecondary,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _dayFilter(BuildContext context) {
    final c = MalateColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DAY OF WEEK',
            style: MalateTypography.labelSmall.copyWith(color: c.textMuted)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            final day = i + 1;
            final isActive = _selectedDays.contains(day);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isActive && _selectedDays.length > 1) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? MalateColors.neonMint.withValues(alpha: 0.12)
                          : c.asphalt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? MalateColors.neonMint.withValues(alpha: 0.6)
                            : c.sidewalk,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[day],
                      style: MalateTypography.labelSmall.copyWith(
                        color: isActive
                            ? MalateColors.neonMint
                            : c.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _hotspotList(BuildContext context, List<_HotspotArea> hotspots,
      double maxCount, Color accent) {
    final c = MalateColors.of(context);

    if (hotspots.isEmpty) {
      return MalateCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.location_searching,
                  color: c.textMuted, size: 40),
              const SizedBox(height: 12),
              Text(
                'Walang hotspot data pa',
                style: MalateTypography.headlineSmall
                    .copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Mag-log ng mas maraming rides para makita\nang mga sikat na pick-up spots mo.',
                style: MalateTypography.bodySmall
                    .copyWith(color: c.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('TOP AREAS',
                style: MalateTypography.neonAccent(accent)
                    .copyWith(fontSize: 11)),
            const Spacer(),
            Text('${hotspots.length} cluster${hotspots.length == 1 ? '' : 's'}',
                style: MalateTypography.labelSmall
                    .copyWith(color: c.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        ...hotspots.asMap().entries.take(10).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _hotspotRow(context, entry.key + 1, entry.value,
                maxCount, accent),
          );
        }),
      ],
    );
  }

  Widget _hotspotRow(BuildContext context, int rank, _HotspotArea area,
      double maxCount, Color accent) {
    final c = MalateColors.of(context);
    final fraction = maxCount > 0 ? area.rideCount / maxCount : 0.0;
    final rankColor = rank == 1
        ? MalateColors.electricAmber
        : rank == 2
            ? MalateColors.cyberCyan
            : rank == 3
                ? MalateColors.neonMint
                : c.textMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank == 1
              ? accent.withValues(alpha: 0.3)
              : c.sidewalk,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '#$rank',
                  style: MalateTypography.headlineSmall
                      .copyWith(color: rankColor, fontSize: 15),
                ),
              ),
              Expanded(
                child: Text(
                  area.name,
                  style: MalateTypography.headlineSmall
                      .copyWith(color: c.textPrimary, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${area.rideCount} rides',
                    style: MalateTypography.bodySmall
                        .copyWith(color: accent, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'avg ${_formatPeso(area.avgEarning)}',
                    style: MalateTypography.labelSmall
                        .copyWith(color: MalateColors.neonMint, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 6,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: c.gutter,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  height: 6,
                  width: constraints.maxWidth * fraction,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: MalateColors.subtleGlow(accent),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 6),
          Text(
            '${(fraction * 100).toStringAsFixed(0)}% of peak',
            style: MalateTypography.labelSmall
                .copyWith(color: c.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    final c = MalateColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MalateColors.cyberCyan.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: MalateColors.cyberCyan, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Based on your ride history. Keep riding to improve accuracy.',
              style: MalateTypography.bodySmall
                  .copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaRef {
  final String name;
  final double lat;
  final double lng;
  const _AreaRef(this.name, this.lat, this.lng);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/ride_log_model.dart';
import '../services/ride_logger.dart';
import '../widgets/earnings_chart.dart';
import '../widgets/malate_card.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    return Scaffold(
      backgroundColor: c.midnight,
      appBar: AppBar(
        backgroundColor: c.midnight,
        automaticallyImplyLeading: false,
        title: Text('EARNINGS',
            style: MalateTypography.neonAccent(MalateColors.neonMint)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.textSecondary),
            onPressed: () => context.read<RideLogger>().refreshLogs(),
          ),
        ],
      ),
      body: Consumer<RideLogger>(
        builder: (context, logger, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _todayCard(context, logger),
              const SizedBox(height: 20),
              EarningsWeeklyChart(rideCounts: logger.weeklyRideCounts),
              const SizedBox(height: 20),
              _weekSummary(context, logger),
              const SizedBox(height: 20),
              _platformBreakdown(context, logger),
              const SizedBox(height: 20),
              _recentRides(context, logger),
              const SizedBox(height: 20),
              _fuelSettings(context, logger),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _todayCard(BuildContext context, RideLogger logger) {
    final c = MalateColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MalateColors.neonMint.withValues(alpha: 0.2)),
        boxShadow: MalateColors.subtleGlow(MalateColors.neonMint),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.today,
                  color: MalateColors.electricAmber, size: 18),
              const SizedBox(width: 8),
              Text('TODAY',
                  style: MalateTypography.neonAccent(
                      MalateColors.electricAmber)),
              const Spacer(),
              Text('${logger.todayRideCount} rides',
                  style: MalateTypography.labelSmall),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatPeso(logger.todayEarnings),
            style: MalateTypography.displayLarge
                .copyWith(color: MalateColors.neonMint, fontSize: 44),
          ),
          const SizedBox(height: 4),
          Text('TOTAL EARNINGS', style: MalateTypography.labelSmall),
          const SizedBox(height: 20),
          Row(
            children: [
              _miniStat(context, Icons.straighten,
                  '${logger.todayDistance.toStringAsFixed(1)} km',
                  'DISTANCE', MalateColors.cyberCyan),
              const SizedBox(width: 12),
              _miniStat(context, Icons.local_gas_station,
                  _formatPeso(logger.todayFuelCost), 'FUEL COST',
                  MalateColors.electricAmber),
              const SizedBox(width: 12),
              _miniStat(context, Icons.account_balance_wallet,
                  _formatPeso(logger.todayEarnings - logger.todayFuelCost),
                  'NET', MalateColors.neonMint),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, IconData icon, String value,
      String label, Color color) {
    final c = MalateColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.midnight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: MalateTypography.headlineSmall
                    .copyWith(fontSize: 13, color: c.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: MalateTypography.labelSmall.copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _weekSummary(BuildContext context, RideLogger logger) {
    final c = MalateColors.of(context);
    return MalateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WEEK SUMMARY',
              style: MalateTypography.neonAccent(MalateColors.cyberCyan)
                  .copyWith(fontSize: 11)),
          const SizedBox(height: 16),
          _summaryRow('Total Earnings', _formatPeso(logger.weekEarnings),
              MalateColors.neonMint),
          Divider(color: c.sidewalk, height: 16),
          _summaryRow('Fuel Cost', _formatPeso(logger.weekFuelCost),
              MalateColors.electricAmber),
          Divider(color: c.sidewalk, height: 16),
          _summaryRow(
              'Net Profit',
              _formatPeso(logger.weekEarnings - logger.weekFuelCost),
              MalateColors.neonMint),
          Divider(color: c.sidewalk, height: 16),
          _summaryRow('Total Distance',
              '${logger.weekDistance.toStringAsFixed(1)} km',
              MalateColors.cyberCyan),
          Divider(color: c.sidewalk, height: 16),
          _summaryRow(
              'Total Rides', '${logger.weekLogs.length}', c.textPrimary),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(label, style: MalateTypography.bodyMedium),
        const Spacer(),
        Text(value,
            style: MalateTypography.headlineSmall
                .copyWith(color: valueColor, fontSize: 15)),
      ],
    );
  }

  Widget _platformBreakdown(BuildContext context, RideLogger logger) {
    final c = MalateColors.of(context);
    final breakdown = logger.earningsByPlatform;
    if (breakdown.isEmpty) {
      return MalateCard(
        child: Column(
          children: [
            Text('PER PLATFORM',
                style: MalateTypography.neonAccent(c.textMuted)
                    .copyWith(fontSize: 11)),
            const SizedBox(height: 12),
            Text('No rides yet this week',
                style: MalateTypography.bodySmall),
          ],
        ),
      );
    }

    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return MalateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PER PLATFORM',
              style: MalateTypography.neonAccent(c.textMuted)
                  .copyWith(fontSize: 11)),
          const SizedBox(height: 12),
          ...sorted.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(e.key.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(e.key.label, style: MalateTypography.bodyMedium),
                    const Spacer(),
                    Text(_formatPeso(e.value),
                        style: MalateTypography.headlineSmall
                            .copyWith(fontSize: 14, color: MalateColors.neonMint)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _recentRides(BuildContext context, RideLogger logger) {
    final c = MalateColors.of(context);
    final recent = logger.todayLogs.take(5).toList();
    if (recent.isEmpty) {
      return MalateCard(
        child: Column(
          children: [
            Text('RECENT RIDES',
                style: MalateTypography.neonAccent(c.textMuted)
                    .copyWith(fontSize: 11)),
            const SizedBox(height: 12),
            Text('Wala pang ride ngayon',
                style: MalateTypography.bodySmall),
          ],
        ),
      );
    }

    return MalateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECENT RIDES',
              style: MalateTypography.neonAccent(c.textMuted)
                  .copyWith(fontSize: 11)),
          const SizedBox(height: 12),
          ...recent.map((ride) => _rideRow(context, ride)),
        ],
      ),
    );
  }

  Widget _rideRow(BuildContext context, RideLog ride) {
    final c = MalateColors.of(context);
    final timeStr = DateFormat('h:mm a').format(ride.startTime);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(ride.platform.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${ride.platform.label} — $timeStr',
                    style: MalateTypography.bodyMedium
                        .copyWith(color: c.textPrimary, fontSize: 13)),
                Text('${ride.distanceText} • ${ride.durationText}',
                    style: MalateTypography.bodySmall),
              ],
            ),
          ),
          Text(
            _formatPeso(ride.estimatedEarning),
            style: MalateTypography.headlineSmall
                .copyWith(fontSize: 14, color: MalateColors.neonMint),
          ),
        ],
      ),
    );
  }

  Widget _fuelSettings(BuildContext context, RideLogger logger) {
    final c = MalateColors.of(context);
    return MalateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VEHICLE SETTINGS',
              style: MalateTypography.neonAccent(MalateColors.electricAmber)
                  .copyWith(fontSize: 11)),
          const SizedBox(height: 16),
          _editableRow(
            context,
            icon: Icons.local_gas_station,
            label: 'Fuel Price',
            value: '₱${logger.fuelPricePerLiter.toStringAsFixed(0)}/L',
            onTap: () => _editNumber(
                context, 'Fuel Price (₱/L)', logger.fuelPricePerLiter,
                (v) => logger.setFuelPrice(v)),
          ),
          Divider(color: c.sidewalk, height: 20),
          _editableRow(
            context,
            icon: Icons.speed,
            label: 'Fuel Efficiency',
            value: '${logger.vehicleKmPerLiter.toStringAsFixed(0)} km/L',
            onTap: () => _editNumber(
                context, 'Efficiency (km/L)', logger.vehicleKmPerLiter,
                (v) => logger.setVehicleEfficiency(v)),
          ),
        ],
      ),
    );
  }

  Widget _editableRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      required VoidCallback onTap}) {
    final c = MalateColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: MalateColors.electricAmber, size: 20),
          const SizedBox(width: 12),
          Text(label, style: MalateTypography.bodyMedium),
          const Spacer(),
          Text(value,
              style: MalateTypography.headlineSmall
                  .copyWith(fontSize: 14, color: c.textPrimary)),
          const SizedBox(width: 8),
          Icon(Icons.edit, color: c.textMuted, size: 16),
        ],
      ),
    );
  }

  void _editNumber(BuildContext context, String title, double current,
      ValueChanged<double> onSave) {
    final c = MalateColors.of(context);
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.asphalt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: MalateTypography.headlineMedium),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: MalateTypography.headlineLarge
              .copyWith(color: MalateColors.neonMint),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: c.gutter,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: c.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) onSave(v);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MalateColors.neonMint,
              foregroundColor: c.midnight,
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  String _formatPeso(double amount) {
    if (amount >= 1000) {
      return '₱${NumberFormat('#,##0').format(amount)}';
    }
    return '₱${amount.toStringAsFixed(0)}';
  }
}

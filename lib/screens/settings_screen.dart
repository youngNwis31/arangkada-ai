import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../core/offline/connectivity_monitor.dart';
import '../core/battery/battery_saver.dart';
import '../services/ride_logger.dart';
import '../widgets/malate_card.dart';
import 'earnings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityMonitor>();
    final battery = context.watch<BatterySaver>();

    return Scaffold(
      backgroundColor: MalateColors.midnight,
      appBar: AppBar(
        backgroundColor: MalateColors.midnight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MalateColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SETTINGS',
            style: MalateTypography.neonAccent(MalateColors.neonMint)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Status Section ──
          _sectionHeader('STATUS'),
          const SizedBox(height: 12),
          MalateCard(
            child: Column(
              children: [
                _statusRow(
                  'Connection',
                  connectivity.statusText,
                  connectivity.isOnline
                      ? MalateColors.neonMint
                      : MalateColors.hazardRed,
                  connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                ),
                const Divider(color: MalateColors.sidewalk),
                _statusRow(
                  'Battery Saver',
                  battery.isStationary ? 'ACTIVE — GPS throttled' : 'MOVING',
                  battery.isStationary
                      ? MalateColors.electricAmber
                      : MalateColors.neonMint,
                  battery.isStationary
                      ? Icons.battery_saver
                      : Icons.speed,
                ),
                const Divider(color: MalateColors.sidewalk),
                _statusRow(
                  'GPS Interval',
                  '${battery.recommendedGpsIntervalMs ~/ 1000}s',
                  MalateColors.cyberCyan,
                  Icons.gps_fixed,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── App Actions ──
          _sectionHeader('FEATURES'),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.cloud_download,
            color: MalateColors.cyberCyan,
            title: 'Offline Maps',
            subtitle: 'Pre-download maps for dead zones',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Offline Maps — coming in next update')),
              );
            },
          ),
          const SizedBox(height: 10),
          _settingsTile(
            icon: Icons.smart_toy,
            color: MalateColors.cyberCyan,
            title: 'AI Model',
            subtitle: 'v0.01 — Rule-based (Local SLM coming soon)',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _settingsTile(
            icon: Icons.record_voice_over,
            color: MalateColors.electricAmber,
            title: 'Voice Navigation',
            subtitle: 'Offline TTS for turn-by-turn directions',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _settingsTile(
            icon: Icons.account_balance_wallet,
            color: MalateColors.neonMint,
            title: 'Earnings Tracker',
            subtitle: 'Track rides, earnings, and fuel costs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarningsScreen()),
              );
            },
          ),

          const SizedBox(height: 32),

          // ── Vehicle Settings ──
          _sectionHeader('VEHICLE'),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final logger = context.watch<RideLogger>();
            return MalateCard(
              child: Column(
                children: [
                  _editableSettingsRow(
                    context,
                    icon: Icons.local_gas_station,
                    label: 'Fuel Price',
                    value: '₱${logger.fuelPricePerLiter.toStringAsFixed(0)}/L',
                    onTap: () => _editVehicleNumber(
                      context,
                      'Fuel Price (₱/L)',
                      logger.fuelPricePerLiter,
                      (v) => logger.setFuelPrice(v),
                    ),
                  ),
                  const Divider(color: MalateColors.sidewalk),
                  _editableSettingsRow(
                    context,
                    icon: Icons.speed,
                    label: 'Fuel Efficiency',
                    value: '${logger.vehicleKmPerLiter.toStringAsFixed(0)} km/L',
                    onTap: () => _editVehicleNumber(
                      context,
                      'Efficiency (km/L)',
                      logger.vehicleKmPerLiter,
                      (v) => logger.setVehicleEfficiency(v),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 32),

          // ── About Section ──
          _sectionHeader('ABOUT'),
          const SizedBox(height: 12),
          MalateCard(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MalateColors.neonMint.withValues(alpha: 0.1),
                    border: Border.all(
                      color: MalateColors.neonMint.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.two_wheeler,
                      color: MalateColors.neonMint, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConfig.appName.toUpperCase(),
                  style: MalateTypography.headlineLarge.copyWith(
                    color: MalateColors.neonMint,
                    letterSpacing: 3,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConfig.appTagline,
                  style: MalateTypography.bodySmall,
                ),
                const SizedBox(height: 20),
                _aboutRow('Developer', AppConfig.developer),
                const Divider(color: MalateColors.sidewalk, height: 24),
                _aboutRow('Version', AppConfig.appVersion),
                const Divider(color: MalateColors.sidewalk, height: 24),
                _aboutRow('Stack', 'Flutter + Mapbox + Firebase'),
                const Divider(color: MalateColors.sidewalk, height: 24),
                _aboutRow('Budget', '₱0 — Free Tier Optimized'),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: MalateColors.midnight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: MalateColors.sidewalk),
                  ),
                  child: Text(
                    'Built for Philippine riders — Grab, FoodPanda, '
                    'MoveIt, Angkas, JoyRide',
                    textAlign: TextAlign.center,
                    style: MalateTypography.bodySmall.copyWith(
                      color: MalateColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              '© 2024 ${AppConfig.developer}',
              style: MalateTypography.labelSmall.copyWith(
                color: MalateColors.textDisabled,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: MalateTypography.neonAccent(MalateColors.textMuted)
          .copyWith(fontSize: 11),
    );
  }

  Widget _statusRow(String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: MalateTypography.bodyMedium),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: MalateTypography.bodySmall),
        const Spacer(),
        Text(
          value,
          style: MalateTypography.headlineSmall.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  Widget _editableSettingsRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: MalateColors.electricAmber, size: 20),
            const SizedBox(width: 12),
            Text(label, style: MalateTypography.bodyMedium),
            const Spacer(),
            Text(value,
                style: MalateTypography.headlineSmall
                    .copyWith(fontSize: 14, color: MalateColors.textPrimary)),
            const SizedBox(width: 8),
            const Icon(Icons.edit, color: MalateColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  void _editVehicleNumber(BuildContext context, String title, double current,
      ValueChanged<double> onSave) {
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MalateColors.asphalt,
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
            fillColor: MalateColors.gutter,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('CANCEL', style: TextStyle(color: MalateColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) onSave(v);
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

  Widget _settingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return MalateCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MalateTypography.headlineSmall.copyWith(fontSize: 15)),
                Text(subtitle, style: MalateTypography.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: MalateColors.textMuted),
        ],
      ),
    );
  }
}

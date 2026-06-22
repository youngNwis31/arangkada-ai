import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../core/offline/connectivity_monitor.dart';
import '../core/offline/tile_cache_manager.dart';
import '../core/battery/battery_saver.dart';
import '../services/ai/llm_service.dart';
import '../services/ai/model_download_manager.dart';
import '../services/ai/gemini_service.dart';
import '../services/ride_logger.dart';
import '../services/night_mode_provider.dart';
import '../services/speed_monitor.dart';
import '../services/voice_command_service.dart';
import '../services/theme_provider.dart';
import '../widgets/malate_card.dart';
import 'earnings_screen.dart';
import 'fare_estimator_screen.dart';
import 'fuel_calculator_screen.dart';
import 'hotspot_screen.dart';
import 'offline_maps_screen.dart';
import 'safety_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    final connectivity = context.watch<ConnectivityMonitor>();
    final battery = context.watch<BatterySaver>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: c.midnight,
      appBar: AppBar(
        backgroundColor: c.midnight,
        automaticallyImplyLeading: false,
        title: Text('SETTINGS',
            style: MalateTypography.neonAccent(MalateColors.neonMint)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          // ── Appearance ──
          _sectionHeader(context, 'APPEARANCE'),
          const SizedBox(height: 12),
          MalateCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      themeProvider.isDark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: MalateColors.electricAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text('Theme', style: MalateTypography.bodyMedium),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _themeChip(context, 'System', ThemeMode.system,
                        themeProvider, Icons.settings_suggest),
                    const SizedBox(width: 8),
                    _themeChip(context, 'Light', ThemeMode.light,
                        themeProvider, Icons.light_mode),
                    const SizedBox(width: 8),
                    _themeChip(context, 'Dark', ThemeMode.dark,
                        themeProvider, Icons.dark_mode),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Consumer<NightModeProvider>(
            builder: (_, nightMode, __) {
              final c = MalateColors.of(context);
              return MalateCard(
                child: Row(
                  children: [
                    Icon(
                      nightMode.isNightMode
                          ? Icons.nightlight_round
                          : Icons.wb_sunny,
                      color: MalateColors.electricAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Night Mode',
                              style: MalateTypography.bodyMedium),
                          Text(
                            'Red-tinted map for night riding',
                            style: MalateTypography.bodySmall
                                .copyWith(color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: nightMode.isNightMode,
                      onChanged: (_) => nightMode.toggle(),
                      activeColor: MalateColors.electricAmber,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // ── Status Section ──
          _sectionHeader(context, 'STATUS'),
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
                Divider(color: c.sidewalk),
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
                Divider(color: c.sidewalk),
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

          // ── Features ──
          _sectionHeader(context, 'FEATURES'),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final cache = context.watch<TileCacheManager>();
            final subtitle = cache.hasDownload
                ? 'Metro Manila — ${cache.storeSizeMB.toStringAsFixed(0)} MB'
                : 'Download maps for dead zones';
            return _settingsTile(
              context,
              icon: Icons.cloud_download,
              color: MalateColors.cyberCyan,
              title: 'Offline Maps',
              subtitle: subtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OfflineMapsScreen()),
              ),
            );
          }),
          const SizedBox(height: 10),

          // ── AI Model Tile (Phase 4) ──
          _aiModelTile(context),
          const SizedBox(height: 10),

          _settingsTile(
            context,
            icon: Icons.record_voice_over,
            color: MalateColors.electricAmber,
            title: 'Voice Navigation',
            subtitle: 'Offline TTS for turn-by-turn directions',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _settingsTile(
            context,
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
          const SizedBox(height: 10),
          _settingsTile(
            context,
            icon: Icons.calculate,
            color: MalateColors.electricAmber,
            title: 'Fare Estimator',
            subtitle: 'Check if a trip is worth it',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FareEstimatorScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _settingsTile(
            context,
            icon: Icons.local_gas_station,
            color: MalateColors.electricAmber,
            title: 'Fuel Calculator',
            subtitle: 'Calculate fuel cost per trip',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FuelCalculatorScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _settingsTile(
            context,
            icon: Icons.map,
            color: MalateColors.cyberCyan,
            title: 'Booking Hotspots',
            subtitle: 'See where you get the most bookings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HotspotScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _settingsTile(
            context,
            icon: Icons.shield,
            color: MalateColors.hazardRed,
            title: 'Rider Safety',
            subtitle: 'SOS, emergency contacts, rest reminders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SafetyScreen()),
              );
            },
          ),

          const SizedBox(height: 32),

          // ── Safety Settings ──
          _sectionHeader(context, 'SAFETY'),
          const SizedBox(height: 12),
          Consumer<SpeedMonitor>(
            builder: (_, speed, __) {
              final c = MalateColors.of(context);
              return MalateCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed,
                            color: MalateColors.hazardRed, size: 20),
                        const SizedBox(width: 12),
                        Text('Speed Limit',
                            style: MalateTypography.bodyMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                MalateColors.hazardRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: MalateColors.hazardRed
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${speed.speedLimitKmh.toInt()} km/h',
                            style: MalateTypography.headlineSmall.copyWith(
                              fontSize: 14,
                              color: MalateColors.hazardRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: MalateColors.hazardRed,
                        inactiveTrackColor: c.sidewalk,
                        thumbColor: MalateColors.hazardRed,
                        overlayColor:
                            MalateColors.hazardRed.withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: speed.speedLimitKmh,
                        min: 30,
                        max: 120,
                        divisions: 18,
                        onChanged: (v) => speed.setSpeedLimit(v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('30 km/h',
                            style: MalateTypography.labelSmall
                                .copyWith(color: c.textMuted)),
                        Text('120 km/h',
                            style: MalateTypography.labelSmall
                                .copyWith(color: c.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Voice warning when you exceed this speed',
                      style: MalateTypography.bodySmall
                          .copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // ── Hands-Free ──
          _sectionHeader(context, 'HANDS-FREE'),
          const SizedBox(height: 12),
          Consumer<VoiceCommandService>(
            builder: (_, voice, __) {
              final c = MalateColors.of(context);
              return MalateCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.hearing,
                            color: MalateColors.cyberCyan, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Auto-Listen',
                                  style: MalateTypography.bodyMedium),
                              Text(
                                'Mic activates every 45s during navigation',
                                style: MalateTypography.bodySmall
                                    .copyWith(color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: voice.autoListenEnabled,
                          onChanged: (_) => voice.toggleAutoListen(),
                          activeColor: MalateColors.cyberCyan,
                        ),
                      ],
                    ),
                    if (voice.autoListenEnabled) ...[
                      const SizedBox(height: 16),
                      Divider(color: c.sidewalk),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.update,
                              color: MalateColors.electricAmber, size: 20),
                          const SizedBox(width: 12),
                          Text('Status Update',
                              style: MalateTypography.bodyMedium),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: MalateColors.electricAmber
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Every ${voice.statusIntervalMinutes} min',
                              style: MalateTypography.headlineSmall.copyWith(
                                fontSize: 12,
                                color: MalateColors.electricAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [15, 30, 60].map((mins) {
                          final selected =
                              voice.statusIntervalMinutes == mins;
                          return GestureDetector(
                            onTap: () => voice.setStatusInterval(mins),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? MalateColors.electricAmber
                                        .withValues(alpha: 0.15)
                                    : c.gutter,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? MalateColors.electricAmber
                                      : c.sidewalk,
                                ),
                              ),
                              child: Text(
                                '${mins}m',
                                style: MalateTypography.labelMedium.copyWith(
                                  color: selected
                                      ? MalateColors.electricAmber
                                      : c.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // ── Vehicle Settings ──
          _sectionHeader(context, 'VEHICLE'),
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
                  Divider(color: c.sidewalk),
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
          _sectionHeader(context, 'ABOUT'),
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
                Divider(color: c.sidewalk, height: 24),
                _aboutRow('Version', AppConfig.appVersion),
                Divider(color: c.sidewalk, height: 24),
                _aboutRow('Stack', 'Flutter + OSM + SQLite'),
                Divider(color: c.sidewalk, height: 24),
                _aboutRow('Budget', '₱0 — Free Tier Optimized'),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.midnight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.sidewalk),
                  ),
                  child: Text(
                    'Built for Philippine riders — Grab, FoodPanda, '
                    'MoveIt, Angkas, JoyRide',
                    textAlign: TextAlign.center,
                    style: MalateTypography.bodySmall.copyWith(
                      color: c.textMuted,
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
                color: c.textDisabled,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _aiModelTile(BuildContext context) {
    final c = MalateColors.of(context);
    final dm = context.watch<ModelDownloadManager>();
    final llm = context.watch<LlmService>();

    String subtitle;
    Color statusColor;
    IconData statusIcon;

    switch (dm.state) {
      case DownloadState.idle:
        subtitle = 'Qwen 0.5B — Tap to manage (~200 MB)';
        statusColor = MalateColors.cyberCyan;
        statusIcon = Icons.download;
      case DownloadState.downloading:
        subtitle = 'Downloading... ${dm.downloadedSizeMB} / ${dm.totalSizeMB} MB';
        statusColor = MalateColors.electricAmber;
        statusIcon = Icons.downloading;
      case DownloadState.paused:
        subtitle = 'Paused — ${dm.downloadedSizeMB} MB downloaded';
        statusColor = MalateColors.electricAmber;
        statusIcon = Icons.pause_circle;
      case DownloadState.verifying:
        subtitle = 'Verifying model...';
        statusColor = MalateColors.electricAmber;
        statusIcon = Icons.verified;
      case DownloadState.done:
        subtitle = 'Ready — Local AI active';
        statusColor = MalateColors.neonMint;
        statusIcon = Icons.psychology;
      case DownloadState.error:
        subtitle = dm.errorMessage ?? 'Error — tap to retry';
        statusColor = MalateColors.hazardRed;
        statusIcon = Icons.error_outline;
    }

    return MalateCard(
      onTap: () => _showAiModelSheet(context),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Model',
                        style: MalateTypography.headlineSmall
                            .copyWith(fontSize: 15)),
                    Text(subtitle, style: MalateTypography.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textMuted),
            ],
          ),
          if (dm.state == DownloadState.downloading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: dm.progress,
                backgroundColor: c.sidewalk,
                valueColor: AlwaysStoppedAnimation(MalateColors.electricAmber),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAiModelSheet(BuildContext context) {
    final c = MalateColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.asphalt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer2<ModelDownloadManager, LlmService>(
          builder: (_, dm, llm, __) {
            final gemini = Provider.of<GeminiService>(ctx, listen: false);
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.sidewalk,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.psychology,
                          color: MalateColors.electricAmber, size: 28),
                      const SizedBox(width: 12),
                      Text('AI MODEL',
                          style: MalateTypography.neonAccent(
                              MalateColors.electricAmber)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // AI Tiers
                  _aiTierRow(
                    context,
                    icon: Icons.menu_book,
                    color: MalateColors.neonMint,
                    name: 'Knowledge Base',
                    status: '100+ topics',
                    isActive: true,
                  ),
                  const SizedBox(height: 12),
                  _aiTierRow(
                    context,
                    icon: Icons.psychology,
                    color: MalateColors.electricAmber,
                    name: 'Local AI (Qwen 0.5B)',
                    status: llm.statusText,
                    isActive: dm.state == DownloadState.done,
                  ),
                  const SizedBox(height: 12),
                  _aiTierRow(
                    context,
                    icon: Icons.cloud,
                    color: MalateColors.cyberCyan,
                    name: 'Gemini Flash (Online)',
                    status: gemini.hasApiKey
                        ? (gemini.isAvailable ? 'Connected' : 'Offline')
                        : 'No API Key',
                    isActive: gemini.hasApiKey,
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  if (dm.state == DownloadState.idle ||
                      dm.state == DownloadState.error) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          dm.startDownload();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('DOWNLOAD QWEN 0.5B (~200 MB)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MalateColors.electricAmber,
                          foregroundColor: c.midnight,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (dm.state == DownloadState.error) ...[
                      const SizedBox(height: 8),
                      Text(
                        dm.errorMessage ?? 'Unknown error',
                        style: MalateTypography.bodySmall
                            .copyWith(color: MalateColors.hazardRed),
                      ),
                    ],
                  ],
                  if (dm.state == DownloadState.downloading) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          dm.cancelDownload();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('CANCEL DOWNLOAD'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MalateColors.hazardRed,
                          side: const BorderSide(color: MalateColors.hazardRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (dm.state == DownloadState.done) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          dm.deleteModel();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('DELETE MODEL'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MalateColors.hazardRed,
                          side: const BorderSide(color: MalateColors.hazardRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('GEMINI API KEY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: MalateColors.cyberCyan,
                        letterSpacing: 1.5,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    gemini.hasApiKey
                        ? 'API key configured — Gemini active when online'
                        : 'Optional: Add a free API key from Google AI Studio',
                    style: MalateTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showApiKeyDialog(context);
                      },
                      icon: Icon(gemini.hasApiKey ? Icons.edit : Icons.key),
                      label: Text(gemini.hasApiKey ? 'CHANGE API KEY' : 'ADD API KEY'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MalateColors.cyberCyan,
                        side: const BorderSide(color: MalateColors.cyberCyan),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _aiTierRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String name,
    required String status,
    required bool isActive,
  }) {
    final c = MalateColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : c.gutter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.3) : c.sidewalk,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: MalateTypography.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.15)
                  : c.sidewalk.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? color : c.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showApiKeyDialog(BuildContext context) {
    final c = MalateColors.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.asphalt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Gemini API Key', style: MalateTypography.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get a free key from Google AI Studio. '
              'Free tier: 15 requests/min, 1,500/day.',
              style: MalateTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: MalateTypography.bodyMedium.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Paste API key here...',
                hintStyle: MalateTypography.bodyMedium.copyWith(color: c.textMuted),
                filled: true,
                fillColor: c.gutter,
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
            child: Text('CANCEL', style: TextStyle(color: c.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                Provider.of<GeminiService>(context, listen: false).setApiKey(key);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MalateColors.cyberCyan,
              foregroundColor: c.midnight,
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _themeChip(BuildContext context, String label, ThemeMode mode,
      ThemeProvider provider, IconData icon) {
    final c = MalateColors.of(context);
    final isSelected = provider.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? MalateColors.neonMint.withValues(alpha: 0.12)
                : c.gutter,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? MalateColors.neonMint : c.sidewalk,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? MalateColors.neonMint : c.textSecondary,
                  size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: MalateTypography.labelMedium.copyWith(
                  color: isSelected ? MalateColors.neonMint : c.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final c = MalateColors.of(context);
    return Text(
      title,
      style: MalateTypography.neonAccent(c.textMuted).copyWith(fontSize: 11),
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
    final c = MalateColors.of(context);
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
                    .copyWith(fontSize: 14, color: c.textPrimary)),
            const SizedBox(width: 8),
            Icon(Icons.edit, color: c.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  void _editVehicleNumber(BuildContext context, String title, double current,
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

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final c = MalateColors.of(context);
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
                Text(title,
                    style:
                        MalateTypography.headlineSmall.copyWith(fontSize: 15)),
                Text(subtitle, style: MalateTypography.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: c.textMuted),
        ],
      ),
    );
  }
}

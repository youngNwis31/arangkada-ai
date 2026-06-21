import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../core/offline/tile_cache_manager.dart';
import '../services/navigation_provider.dart';
import '../services/offline_nav_engine.dart';
import '../services/fatigue_monitor.dart';
import '../services/speed_monitor.dart';
import '../widgets/nav_instruction_card.dart';
import '../widgets/crash_alert_overlay.dart';
import '../widgets/voice_fab.dart';
import '../widgets/flood_marker.dart';
import '../services/hazard_service.dart';
import '../models/hazard_report.dart';

Widget _darkTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      -0.6, 0, 0, 0, 130,
      0, -0.6, 0, 0, 130,
      0, 0, -0.6, 0, 130,
      0, 0, 0, 1, 0,
    ]),
    child: tileWidget,
  );
}

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  bool _initialZoomDone = false;
  List<HazardReport> _floodReports = [];
  bool _showFloodBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().startNavigation();
      _checkFloodZones();
    });
  }

  Future<void> _checkFloodZones() async {
    final nav = context.read<NavigationProvider>();
    final route = nav.selectedRoute;
    if (route == null) return;
    final floods = await HazardService.getFloodReportsAlongRoute(
        route.coordinates);
    if (mounted && floods.isNotEmpty) {
      setState(() {
        _floodReports = floods;
        _showFloodBanner = true;
      });
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _showFloodBanner = false);
      });
    }
  }

  LatLng _riderPosition(NavigationProvider nav) {
    final pos = nav.navEngine.lastPosition;
    if (pos != null && _isInPH(pos.latitude, pos.longitude)) {
      return LatLng(pos.latitude, pos.longitude);
    }
    final route = nav.navEngine.route ?? nav.selectedRoute;
    if (route != null && route.coordinates.isNotEmpty) {
      final first = route.coordinates.first;
      return LatLng(first[1], first[0]);
    }
    final o = nav.origin;
    if (o != null) return LatLng(o.latitude, o.longitude);
    return LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
  }

  bool _isInPH(double lat, double lng) {
    return lat >= 4.5 && lat <= 21.5 && lng >= 116.0 && lng <= 127.0;
  }

  List<Polyline> _buildRoutePolyline(NavigationProvider nav) {
    final route = nav.navEngine.route ?? nav.selectedRoute;
    if (route == null) return [];

    final points = route.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    return [
      Polyline(
        points: points,
        color: MalateColors.neonMint,
        strokeWidth: 7.0,
      ),
    ];
  }

  void _fitRoute(NavigationProvider nav) {
    final route = nav.navEngine.route ?? nav.selectedRoute;
    if (route == null || route.coordinates.isEmpty) return;

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final c in route.coordinates) {
      if (c[1] < minLat) minLat = c[1];
      if (c[1] > maxLat) maxLat = c[1];
      if (c[0] < minLng) minLng = c[0];
      if (c[0] > maxLng) maxLng = c[0];
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.fromLTRB(50, 100, 50, 280),
      ),
    );
  }

  void _followRider(NavigationProvider nav) {
    final pos = _riderPosition(nav);
    final heading = nav.navEngine.lastPosition?.heading ?? 0;
    _mapController.moveAndRotate(pos, 17.0, heading.isNaN ? 0 : heading);
  }

  void _onExit() {
    context.read<NavigationProvider>().stopNavigation();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.midnight,
      body: Consumer<NavigationProvider>(
        builder: (context, nav, _) {
          final engine = nav.navEngine;
          final rider = _riderPosition(nav);

          if (!_initialZoomDone && engine.isNavigating) {
            _initialZoomDone = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitRoute(nav);
            });
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: rider,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? AppConfig.osmTileUrlDark
                        : AppConfig.osmTileUrl,
                    userAgentPackageName: 'com.arangkada.arangkadaAi',
                    maxZoom: 19,
                    retinaMode: true,
                    tileProvider: context.read<TileCacheManager>().tileProvider,
                    tileBuilder: isDark ? _darkTileBuilder : null,
                  ),
                  PolylineLayer(polylines: _buildRoutePolyline(nav)),
                  if (_floodReports.isNotEmpty)
                    MarkerLayer(
                      markers: _floodReports.map((report) => Marker(
                        point: LatLng(report.latitude, report.longitude),
                        width: 32,
                        height: 32,
                        child: FloodMarker(report: report),
                      )).toList(),
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: rider,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: MalateColors.neonMint,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: MalateColors.neonGlow(
                                MalateColors.neonMint, intensity: 0.4),
                          ),
                        ),
                      ),
                      if (nav.destination != null)
                        Marker(
                          point: LatLng(nav.destination!.latitude,
                              nav.destination!.longitude),
                          width: 32,
                          height: 32,
                          child: const Icon(Icons.location_on,
                              color: MalateColors.hazardRed, size: 32),
                        ),
                    ],
                  ),
                ],
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _topStrip(engine),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (engine.state == NavState.arrived)
                        _arrivedCard()
                      else
                        NavInstructionCard(engine: engine),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                right: 16,
                child: Column(
                  children: [
                    _controlButton(
                      engine.voiceEnabled ? Icons.volume_up : Icons.volume_off,
                      engine.voiceEnabled
                          ? MalateColors.cyberCyan
                          : c.textMuted,
                      engine.toggleVoice,
                    ),
                    const SizedBox(height: 10),
                    _controlButton(
                      Icons.my_location,
                      MalateColors.neonMint,
                      () => _followRider(nav),
                    ),
                    const SizedBox(height: 10),
                    _controlButton(
                      Icons.zoom_out_map,
                      MalateColors.cyberCyan,
                      () => _fitRoute(nav),
                    ),
                    const SizedBox(height: 10),
                    _controlButton(
                      Icons.close,
                      MalateColors.hazardRed,
                      _onExit,
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 200,
                left: 16,
                child: const VoiceFab(),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 16,
                child: Consumer<SpeedMonitor>(
                  builder: (_, speed, __) {
                    final kmh = speed.currentSpeedKmh.toInt();
                    final over = speed.isOverLimit;
                    final color = over
                        ? MalateColors.hazardRed
                        : MalateColors.neonMint;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.asphalt.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: color.withValues(alpha: 0.6)),
                        boxShadow: over
                            ? MalateColors.neonGlow(
                                MalateColors.hazardRed,
                                intensity: 0.4)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$kmh',
                            style: MalateTypography.headlineLarge.copyWith(
                              color: color,
                              fontSize: 28,
                            ),
                          ),
                          Text(
                            'km/h',
                            style: MalateTypography.labelSmall
                                .copyWith(color: color),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Consumer<FatigueMonitor>(
                builder: (_, fatigue, __) {
                  if (!fatigue.shouldRest) return const SizedBox.shrink();
                  final color = fatigue.mustRest
                      ? MalateColors.hazardRed
                      : MalateColors.electricAmber;
                  return Positioned(
                    top: MediaQuery.of(context).padding.top + 140,
                    left: 16,
                    child: GestureDetector(
                      onTap: fatigue.markRest,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: c.asphalt.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: color.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, color: color, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              fatigue.rideTimeText,
                              style: MalateTypography.labelLarge
                                  .copyWith(color: color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              if (_showFloodBanner)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 90,
                  right: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: MalateColors.cyberCyan.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.water_drop,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'FLOOD ZONE AHEAD — ${_floodReports.length} report${_floodReports.length > 1 ? 's' : ''}',
                            style: MalateTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showFloodBanner = false),
                          child: const Icon(Icons.close,
                              color: Colors.white70, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              const Positioned.fill(
                child: CrashAlertOverlay(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _topStrip(OfflineNavEngine engine) {
    final c = MalateColors.of(context);
    final street = engine.currentStreet;
    if (street.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.asphalt.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.sidewalk),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: MalateColors.neonMint, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              street,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MalateTypography.headlineSmall
                  .copyWith(color: c.textPrimary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: MalateColors.neonMint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'NAV',
              style: MalateTypography.labelSmall
                  .copyWith(color: MalateColors.neonMint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrivedCard() {
    final c = MalateColors.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MalateColors.neonMint.withValues(alpha: 0.4)),
        boxShadow: MalateColors.neonGlow(MalateColors.neonMint, intensity: 0.3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: MalateColors.neonMint.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag, color: MalateColors.neonMint, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Nakarating ka na!',
            style: MalateTypography.headlineLarge
                .copyWith(color: MalateColors.neonMint),
          ),
          const SizedBox(height: 6),
          Text(
            'You have arrived at your destination.',
            style: MalateTypography.bodyMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _onExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MalateColors.neonMint,
                foregroundColor: c.midnight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('TAPOS NA',
                  style: MalateTypography.labelLarge.copyWith(color: c.midnight)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, Color color, VoidCallback onTap) {
    final c = MalateColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: c.asphalt.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

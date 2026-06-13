import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../core/offline/connectivity_monitor.dart';
import '../services/navigation_provider.dart';
import '../widgets/signal_indicator.dart';
import '../widgets/route_info_card.dart';
import '../widgets/ride_toggle.dart';
import 'search_screen.dart';
import 'hazard_report_screen.dart';
import 'ai_assistant_screen.dart';
import 'earnings_screen.dart';
import 'settings_screen.dart';
import 'navigation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  PointAnnotationManager? _pointManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().initLocation();
    });
  }

  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _polylineManager = await map.annotations.createPolylineAnnotationManager();
    _pointManager = await map.annotations.createPointAnnotationManager();

    if (!mounted) return;
    final nav = context.read<NavigationProvider>();
    if (nav.currentLocation != null) {
      _flyTo(nav.currentLocation!.latitude, nav.currentLocation!.longitude);
    }
  }

  void _flyTo(double lat, double lng) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: AppConfig.defaultZoom,
      ),
      MapAnimationOptions(duration: 800),
    );
  }

  void _drawRoutes(NavigationProvider nav) async {
    final c = MalateColors.of(context);
    await _polylineManager?.deleteAll();
    await _pointManager?.deleteAll();
    if (nav.routes.isEmpty) return;
    for (int i = nav.routes.length - 1; i >= 0; i--) {
      final route = nav.routes[i];
      final isSelected = i == nav.selectedRouteIndex;
      final points = route.coordinates
          .map((c) => Position(c[0], c[1]))
          .toList();

      await _polylineManager?.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: points),
        lineColor: isSelected
            ? MalateColors.neonMint.toARGB32()
            : c.textMuted.toARGB32(),
        lineWidth: isSelected ? 6.0 : 3.0,
        lineOpacity: isSelected ? 1.0 : 0.4,
      ));
    }

    _fitBounds(nav);
  }

  void _fitBounds(NavigationProvider nav) {
    if (nav.currentLocation == null || nav.destination == null) return;
    final o = nav.currentLocation!;
    final d = nav.destination!;

    final swLat = o.latitude < d.latitude ? o.latitude : d.latitude;
    final swLng = o.longitude < d.longitude ? o.longitude : d.longitude;
    final neLat = o.latitude > d.latitude ? o.latitude : d.latitude;
    final neLng = o.longitude > d.longitude ? o.longitude : d.longitude;

    _mapboxMap
        ?.cameraForCoordinateBounds(
          CoordinateBounds(
            southwest:
                Point(coordinates: Position(swLng - 0.01, swLat - 0.01)),
            northeast:
                Point(coordinates: Position(neLng + 0.01, neLat + 0.01)),
            infiniteBounds: false,
          ),
          MbxEdgeInsets(top: 120, left: 50, bottom: 320, right: 50),
          null,
          null,
          null,
          null,
        )
        .then((cam) =>
            _mapboxMap?.flyTo(cam, MapAnimationOptions(duration: 800)));
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.read<ConnectivityMonitor>();
    final c = MalateColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.midnight,
      body: Consumer<NavigationProvider>(
        builder: (context, nav, _) {
          if (nav.routes.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _drawRoutes(nav));
          }

          return Stack(
            children: [
              // ── Map ──
              MapWidget(
                key: const ValueKey('arangkada_map'),
                mapOptions: MapOptions(
                  pixelRatio: MediaQuery.of(context).devicePixelRatio,
                ),
                styleUri: isDark ? AppConfig.mapboxStyleDark : AppConfig.mapboxStyleLight,
                viewport: CameraViewportState(
                  center: Point(
                    coordinates: Position(
                      nav.currentLocation?.longitude ?? AppConfig.defaultLng,
                      nav.currentLocation?.latitude ?? AppConfig.defaultLat,
                    ),
                  ),
                  zoom: AppConfig.defaultZoom,
                ),
                onMapCreated: _onMapCreated,
              ),

              // ── Top Bar: Search + Signal ──
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSearchBar(nav)),
                          const SizedBox(width: 10),
                          _buildIconButton(Icons.settings, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SignalIndicator(connectivity: connectivity),
                          const Spacer(),
                          Text(
                            'ARANGKADA AI',
                            style: MalateTypography.labelSmall.copyWith(
                              color: MalateColors.neonMint.withValues(alpha: 0.5),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Loading ──
              if (nav.isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: MalateColors.neonMint,
                    strokeWidth: 2,
                  ),
                ),

              // ── Error ──
              if (nav.error != null && nav.routes.isEmpty)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MalateColors.hazardRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: MalateColors.hazardRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      nav.error!,
                      style: MalateTypography.bodyMedium
                          .copyWith(color: MalateColors.hazardRed),
                    ),
                  ),
                ),

              // ── Route Info Bottom Sheet ──
              if (nav.routes.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Start Navigation button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NavigationScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation, size: 22),
                            label: Text(
                              'START NAVIGATION',
                              style: MalateTypography.labelLarge
                                  .copyWith(color: c.midnight),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MalateColors.neonMint,
                              foregroundColor: c.midnight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      RouteInfoCard(
                        routes: nav.routes,
                        selectedIndex: nav.selectedRouteIndex,
                        onRouteSelected: nav.selectRoute,
                      ),
                    ],
                  ),
                ),

              // ── Ride Toggle (when no route shown) ──
              if (!nav.hasRoute)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: const RideToggle(),
                ),

              // ── FABs ──
              Positioned(
                bottom: nav.hasRoute ? 340 : 30,
                right: 16,
                child: Column(
                  children: [
                    _buildFab(
                        Icons.account_balance_wallet, MalateColors.electricAmber,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EarningsScreen()),
                      );
                    }),
                    const SizedBox(height: 10),
                    _buildFab(Icons.smart_toy, MalateColors.cyberCyan, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AiAssistantScreen()),
                      );
                    }),
                    const SizedBox(height: 10),
                    _buildFab(Icons.warning_amber_rounded,
                        MalateColors.electricAmber, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HazardReportScreen(
                            currentLocation: nav.currentLocation,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    _buildFab(Icons.my_location, MalateColors.neonMint, () {
                      if (nav.currentLocation != null) {
                        _flyTo(nav.currentLocation!.latitude,
                            nav.currentLocation!.longitude);
                      }
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(NavigationProvider nav) {
    final c = MalateColors.of(context);
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SearchScreen(currentLocation: nav.currentLocation),
          ),
        );
        if (result != null && mounted) {
          nav.setDestination(result['location']);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.asphalt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.sidewalk),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: c.textMuted, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nav.destination?.name ?? 'Saan ka pupunta, rider?',
                style: MalateTypography.bodyLarge.copyWith(
                  color: nav.destination != null
                      ? c.textPrimary
                      : c.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (nav.destination != null)
              GestureDetector(
                onTap: () {
                  nav.clearRoute();
                  _polylineManager?.deleteAll();
                  _pointManager?.deleteAll();
                },
                child: Icon(Icons.close,
                    color: c.textMuted, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    final c = MalateColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: c.asphalt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.sidewalk),
        ),
        child: Icon(icon, color: c.textSecondary, size: 22),
      ),
    );
  }

  Widget _buildFab(IconData icon, Color color, VoidCallback onTap) {
    final c = MalateColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: c.asphalt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: MalateColors.subtleGlow(color),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme/malate_colors.dart';
import '../models/location_model.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().initLocation();
    });
  }

  void _flyTo(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), AppConfig.defaultZoom);
  }

  List<Polyline> _buildPolylines(NavigationProvider nav) {
    final c = MalateColors.of(context);
    final polylines = <Polyline>[];
    for (int i = nav.routes.length - 1; i >= 0; i--) {
      final route = nav.routes[i];
      final isSelected = i == nav.selectedRouteIndex;
      final points = route.coordinates
          .map((coord) => LatLng(coord[1], coord[0]))
          .toList();

      polylines.add(Polyline(
        points: points,
        color: isSelected
            ? MalateColors.neonMint
            : c.textMuted.withValues(alpha: 0.4),
        strokeWidth: isSelected ? 6.0 : 3.0,
      ));
    }
    return polylines;
  }

  void _fitBounds(NavigationProvider nav) {
    if (nav.routes.isEmpty) return;
    final route = nav.selectedRoute;
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
        padding: const EdgeInsets.fromLTRB(50, 120, 50, 320),
      ),
    );
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
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _fitBounds(nav));
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    nav.currentLocation?.latitude ?? AppConfig.defaultLat,
                    nav.currentLocation?.longitude ?? AppConfig.defaultLng,
                  ),
                  initialZoom: AppConfig.defaultZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? AppConfig.osmTileUrlDark
                        : AppConfig.osmTileUrl,
                    userAgentPackageName: 'com.arangkada.arangkadaAi',
                    maxZoom: 19,
                    retinaMode: true,
                    tileBuilder: isDark ? _darkTileBuilder : null,
                  ),
                  if (nav.routes.isNotEmpty)
                    PolylineLayer(polylines: _buildPolylines(nav)),
                  if (nav.currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            nav.currentLocation!.latitude,
                            nav.currentLocation!.longitude,
                          ),
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: MalateColors.neonMint,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: MalateColors.subtleGlow(
                                  MalateColors.neonMint),
                            ),
                          ),
                        ),
                        if (nav.destination != null)
                          Marker(
                            point: LatLng(
                              nav.destination!.latitude,
                              nav.destination!.longitude,
                            ),
                            width: 32,
                            height: 32,
                            child: const Icon(
                              Icons.location_on,
                              color: MalateColors.hazardRed,
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                ],
              ),

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

              if (nav.isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: MalateColors.neonMint,
                    strokeWidth: 2,
                  ),
                ),

              if (nav.error != null && nav.routes.isEmpty)
                Positioned(
                  bottom: 200,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.asphalt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: MalateColors.hazardRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: MalateColors.hazardRed, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            nav.error!,
                            style: MalateTypography.bodySmall
                                .copyWith(color: MalateColors.hazardRed),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => nav.clearRoute(),
                          child: Icon(Icons.close,
                              color: c.textMuted, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),

              if (nav.routes.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

              if (!nav.hasRoute)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: RideToggle(),
                    ),
                  ),
                ),

              Positioned(
                bottom: nav.hasRoute ? 340 : 110,
                right: 16,
                child: Column(
                  children: [
                    _buildFab(
                        Icons.account_balance_wallet, MalateColors.electricAmber,
                        () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EarningsScreen()));
                    }),
                    const SizedBox(height: 10),
                    _buildFab(Icons.smart_toy, MalateColors.cyberCyan, () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
                    }),
                    const SizedBox(height: 10),
                    _buildFab(Icons.warning_amber_rounded, MalateColors.electricAmber, () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => HazardReportScreen(currentLocation: nav.currentLocation),
                      ));
                    }),
                    const SizedBox(height: 10),
                    _buildFab(Icons.my_location, MalateColors.neonMint, () {
                      if (nav.currentLocation != null) {
                        _flyTo(nav.currentLocation!.latitude, nav.currentLocation!.longitude);
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
            builder: (_) => SearchScreen(currentLocation: nav.currentLocation),
          ),
        );
        if (result != null && mounted) {
          final origin = result['origin'] as LocationModel?;
          final dest = result['location'] as LocationModel;
          if (origin != null) {
            nav.setRoute(from: origin, to: dest);
          } else {
            nav.setDestination(dest);
          }
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
                  color: nav.destination != null ? c.textPrimary : c.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (nav.destination != null)
              GestureDetector(
                onTap: () => nav.clearRoute(),
                child: Icon(Icons.close, color: c.textMuted, size: 18),
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

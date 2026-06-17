import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme/malate_colors.dart';
import '../models/location_model.dart';
import '../config/theme/malate_typography.dart';
import '../core/offline/connectivity_monitor.dart';
import '../core/offline/tile_cache_manager.dart';
import '../services/navigation_provider.dart';
import '../services/poi_service.dart';
import '../widgets/signal_indicator.dart';
import '../widgets/route_info_card.dart';
import '../widgets/ride_toggle.dart';
import 'search_screen.dart';
import 'hazard_report_screen.dart';
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
  List<LocationModel> _pois = [];
  PoiCategory? _activeCategory;
  final bool _showPois = true;

  static const _poiChips = [
    PoiCategory.cafe,
    PoiCategory.restaurant,
    PoiCategory.gasStation,
    PoiCategory.bank,
    PoiCategory.convenience,
    PoiCategory.pharmacy,
    PoiCategory.parking,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().initLocation();
      _loadDefaultPois();
    });
  }

  Future<void> _loadDefaultPois() async {
    final nav = context.read<NavigationProvider>();
    final lat = nav.currentLocation?.latitude ?? AppConfig.defaultLat;
    final lng = nav.currentLocation?.longitude ?? AppConfig.defaultLng;
    final results = await PoiService.fetchAllNearby(lat: lat, lng: lng);
    if (mounted) {
      setState(() {
        _pois = results;
        _activeCategory = null;
      });
    }
  }

  Future<void> _loadCategoryPois(PoiCategory category) async {
    if (_activeCategory == category) {
      _loadDefaultPois();
      return;
    }
    final nav = context.read<NavigationProvider>();
    final lat = nav.currentLocation?.latitude ?? AppConfig.defaultLat;
    final lng = nav.currentLocation?.longitude ?? AppConfig.defaultLng;
    setState(() {
      _activeCategory = category;
    });
    final results = await PoiService.fetchByCategory(
      lat: lat,
      lng: lng,
      category: category,
      radius: 2000,
    );
    if (mounted) {
      setState(() {
        _pois = results;
      });
    }
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
                    tileProvider: context.read<TileCacheManager>().tileProvider,
                    tileBuilder: isDark ? _darkTileBuilder : null,
                  ),
                  if (nav.routes.isNotEmpty)
                    PolylineLayer(polylines: _buildPolylines(nav)),
                  if (_showPois && _pois.isNotEmpty)
                    MarkerLayer(
                      markers: _pois.map((poi) => Marker(
                        point: LatLng(poi.latitude, poi.longitude),
                        width: 120,
                        height: 40,
                        child: _PoiMarker(poi: poi, onTap: () => _onPoiTap(poi)),
                      )).toList(),
                    ),
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
                      _buildSearchBar(nav),
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
                      if (!nav.hasRoute) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _poiChips.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                            itemBuilder: (_, i) => _buildPoiChip(_poiChips[i]),
                          ),
                        ),
                      ],
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

  Widget _buildPoiChip(PoiCategory category) {
    final c = MalateColors.of(context);
    final isActive = _activeCategory == category;
    return GestureDetector(
      onTap: () => _loadCategoryPois(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? MalateColors.neonMint : c.asphalt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? MalateColors.neonMint
                : c.sidewalk,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              category.label,
              style: MalateTypography.labelSmall.copyWith(
                color: isActive ? c.midnight : c.textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPoiTap(LocationModel poi) {
    final c = MalateColors.of(context);
    final nav = context.read<NavigationProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: c.asphalt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: c.sidewalk,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: MalateColors.neonMint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _poiIcon(poi.placeType),
                    color: MalateColors.neonMint,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name ?? 'Unknown',
                        style: MalateTypography.headlineSmall.copyWith(
                          color: c.textPrimary, fontSize: 16,
                        ),
                      ),
                      if (poi.address != null && poi.address!.isNotEmpty)
                        Text(
                          poi.address!,
                          style: MalateTypography.bodySmall.copyWith(
                            color: c.textMuted, fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  nav.setDestination(poi);
                },
                icon: const Icon(Icons.directions, size: 20),
                label: Text('NAVIGATE HERE',
                    style: MalateTypography.labelLarge.copyWith(color: c.midnight)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MalateColors.neonMint,
                  foregroundColor: c.midnight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _poiIcon(String? type) {
    return switch (type) {
      'food' => Icons.restaurant,
      'health' => Icons.local_hospital,
      'education' => Icons.school,
      'finance' => Icons.account_balance,
      'worship' => Icons.church,
      'fuel' => Icons.local_gas_station,
      'emergency' => Icons.local_police,
      'shop' => Icons.storefront,
      'parking' => Icons.local_parking,
      _ => Icons.place,
    };
  }
}

class _PoiMarker extends StatelessWidget {
  final LocationModel poi;
  final VoidCallback onTap;
  const _PoiMarker({required this.poi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    final color = _markerColor(poi.placeType);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: c.asphalt.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconForType(poi.placeType), size: 12, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    poi.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 10, color: color),
        ],
      ),
    );
  }

  static Color _markerColor(String? type) {
    return switch (type) {
      'food' => const Color(0xFFFF6B35),
      'health' => MalateColors.hazardRed,
      'finance' => const Color(0xFF4A90D9),
      'fuel' => MalateColors.electricAmber,
      'shop' => MalateColors.cyberCyan,
      'parking' => const Color(0xFF8B5CF6),
      _ => MalateColors.neonMint,
    };
  }

  static IconData _iconForType(String? type) {
    return switch (type) {
      'food' => Icons.restaurant,
      'health' => Icons.local_hospital,
      'finance' => Icons.account_balance,
      'fuel' => Icons.local_gas_station,
      'shop' => Icons.storefront,
      'parking' => Icons.local_parking,
      'worship' => Icons.church,
      'education' => Icons.school,
      _ => Icons.place,
    };
  }
}

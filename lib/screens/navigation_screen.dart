import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../services/navigation_provider.dart';
import '../services/offline_nav_engine.dart';
import '../widgets/nav_instruction_card.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  bool _routeDrawn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().startNavigation();
    });
  }

  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _polylineManager = await map.annotations.createPolylineAnnotationManager();
    _drawRoute();
  }

  void _drawRoute() async {
    if (_routeDrawn || _polylineManager == null) return;
    final nav = context.read<NavigationProvider>();
    final route = nav.navEngine.route ?? nav.selectedRoute;
    if (route == null) return;

    final points =
        route.coordinates.map((c) => Position(c[0], c[1])).toList();

    await _polylineManager!.create(PolylineAnnotationOptions(
      geometry: LineString(coordinates: points),
      lineColor: MalateColors.neonMint.toARGB32(),
      lineWidth: 7.0,
      lineOpacity: 1.0,
    ));
    _routeDrawn = true;
  }

  void _followRider(NavigationProvider nav) {
    final pos = nav.navEngine.lastPosition;
    if (pos == null || _mapboxMap == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(pos.longitude, pos.latitude)),
        zoom: 17.0,
        bearing: pos.heading.isNaN ? 0 : pos.heading,
        pitch: 50,
      ),
      MapAnimationOptions(duration: 600),
    );
  }

  void _onExit() {
    context.read<NavigationProvider>().stopNavigation();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MalateColors.midnight,
      body: Consumer<NavigationProvider>(
        builder: (context, nav, _) {
          final engine = nav.navEngine;

          if (engine.isNavigating && engine.lastPosition != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _followRider(nav);
              if (!_routeDrawn) _drawRoute();
            });
          }

          return Stack(
            children: [
              MapWidget(
                key: const ValueKey('nav_map'),
                mapOptions: MapOptions(
                  pixelRatio: MediaQuery.of(context).devicePixelRatio,
                ),
                styleUri: AppConfig.mapboxStyleDark,
                viewport: CameraViewportState(
                  center: Point(
                    coordinates: Position(
                      nav.currentLocation?.longitude ?? AppConfig.defaultLng,
                      nav.currentLocation?.latitude ?? AppConfig.defaultLat,
                    ),
                  ),
                  zoom: 17.0,
                ),
                onMapCreated: _onMapCreated,
              ),

              // Top strip: current street
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _topStrip(engine),
                ),
              ),

              // Bottom: instruction card
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

              // Exit / voice toggle buttons
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                right: 16,
                child: Column(
                  children: [
                    _controlButton(
                      engine.voiceEnabled ? Icons.volume_up : Icons.volume_off,
                      engine.voiceEnabled
                          ? MalateColors.cyberCyan
                          : MalateColors.textMuted,
                      engine.toggleVoice,
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
            ],
          );
        },
      ),
    );
  }

  Widget _topStrip(OfflineNavEngine engine) {
    final street = engine.currentStreet;
    if (street.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: MalateColors.asphalt.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MalateColors.sidewalk),
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
                  .copyWith(color: MalateColors.textPrimary),
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MalateColors.asphalt,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MalateColors.neonMint.withValues(alpha: 0.4)),
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
            child:
                const Icon(Icons.flag, color: MalateColors.neonMint, size: 36),
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
                foregroundColor: MalateColors.midnight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('TAPOS NA',
                  style: MalateTypography.labelLarge
                      .copyWith(color: MalateColors.midnight)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: MalateColors.asphalt.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  @override
  void dispose() {
    _polylineManager = null;
    super.dispose();
  }
}

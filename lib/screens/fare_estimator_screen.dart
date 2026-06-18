import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/location_model.dart';
import '../services/fare_calculator.dart';
import '../services/mapbox_service.dart';
import '../services/navigation_provider.dart';
import '../services/ride_logger.dart';
import 'navigation_screen.dart';
import 'search_screen.dart';

class FareEstimatorScreen extends StatefulWidget {
  const FareEstimatorScreen({super.key});

  @override
  State<FareEstimatorScreen> createState() => _FareEstimatorScreenState();
}

class _FareEstimatorScreenState extends State<FareEstimatorScreen> {
  LocationModel? _pickup;
  LocationModel? _destination;
  final _fareController = TextEditingController();

  FareEstimateResult? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    if (_pickup == null || _destination == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final routes = await MapboxService.getRoutes(
        origin: _pickup!,
        destination: _destination!,
      );
      if (routes.isEmpty) {
        setState(() {
          _error = 'No route found';
          _isLoading = false;
        });
        return;
      }

      final route = routes.first;
      if (!mounted) return;
      final logger = context.read<RideLogger>();
      final distanceKm = route.distance / 1000;
      final durationMin = route.duration / 60;
      _calculate(distanceKm, durationMin, logger);
    } catch (_) {
      setState(() {
        _error = 'Route fetch failed — check connection';
        _isLoading = false;
      });
    }
  }

  void _calculate(double distanceKm, double durationMin, RideLogger logger) {
    final fare = double.tryParse(_fareController.text);
    setState(() {
      _result = FareCalculator.calculate(
        distanceKm: distanceKm,
        durationMin: durationMin,
        fuelPricePerLiter: logger.fuelPricePerLiter,
        kmPerLiter: logger.vehicleKmPerLiter,
        fareAmount: fare,
        hourlyTarget: 100.0,
      );
      _isLoading = false;
    });
  }

  void _recalculate() {
    if (_result == null) return;
    final logger = context.read<RideLogger>();
    _calculate(_result!.distanceKm, _result!.durationMin, logger);
  }

  Future<void> _selectLocation(bool isPickup) async {
    final nav = context.read<NavigationProvider>();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(currentLocation: nav.currentLocation),
      ),
    );
    if (result != null && mounted) {
      final location = result['location'] as LocationModel;
      setState(() {
        if (isPickup) {
          _pickup = location;
        } else {
          _destination = location;
        }
      });
      if (_pickup != null && _destination != null) {
        _fetchRoute();
      }
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
          'FARE ESTIMATOR',
          style: MalateTypography.labelLarge.copyWith(
            color: MalateColors.electricAmber,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _locationCard(c),
            const SizedBox(height: 16),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: MalateColors.electricAmber,
                  ),
                ),
              ),

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MalateColors.hazardRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MalateColors.hazardRed.withValues(alpha: 0.3)),
                ),
                child: Text(_error!, style: TextStyle(color: MalateColors.hazardRed)),
              ),

            if (_result != null && !_isLoading) ...[
              _tripDetailsCard(c),
              const SizedBox(height: 16),
              _costAnalysisCard(c),
              const SizedBox(height: 16),
              _verdictCard(c),
              const SizedBox(height: 16),
              _actionButtons(c),
            ],
          ],
        ),
      ),
    );
  }

  Widget _locationCard(dynamic c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.gutter),
      ),
      child: Column(
        children: [
          _locationRow(
            c,
            icon: Icons.trip_origin,
            color: MalateColors.neonMint,
            label: _pickup?.name ?? 'Select pickup',
            onTap: () => _selectLocation(true),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Divider(color: c.sidewalk),
          ),
          _locationRow(
            c,
            icon: Icons.location_on,
            color: MalateColors.hazardRed,
            label: _destination?.name ?? 'Select destination',
            onTap: () => _selectLocation(false),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(
    dynamic c, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: MalateTypography.bodyMedium.copyWith(
                  color: label.startsWith('Select') ? c.textMuted : c.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _tripDetailsCard(dynamic c) {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.gutter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('TRIP DETAILS', MalateColors.cyberCyan),
          const SizedBox(height: 12),
          _detailRow(c, 'Distance', '${r.distanceKm.toStringAsFixed(1)} km'),
          Divider(color: c.sidewalk, height: 20),
          _detailRow(c, 'OSRM Time', '${r.durationMin.toStringAsFixed(0)} min'),
          Divider(color: c.sidewalk, height: 20),
          _detailRow(
            c,
            'Est. w/ Traffic',
            '${r.estimatedDurationMin.toStringAsFixed(0)} min',
            valueColor: MalateColors.electricAmber,
          ),
        ],
      ),
    );
  }

  Widget _costAnalysisCard(dynamic c) {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.gutter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('COST ANALYSIS', MalateColors.electricAmber),
          const SizedBox(height: 12),
          _detailRow(c, 'Fuel Needed', '${r.fuelLiters.toStringAsFixed(2)} L'),
          Divider(color: c.sidewalk, height: 20),
          _detailRow(c, 'Fuel Cost', '₱${r.fuelCost.toStringAsFixed(2)}'),
          Divider(color: c.sidewalk, height: 20),
          _detailRow(c, 'Cost / km', '₱${r.costPerKm.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _verdictCard(dynamic c) {
    final r = _result!;
    final verdictColor = switch (r.verdict) {
      FareVerdict.sulit => MalateColors.neonMint,
      FareVerdict.puwede => MalateColors.electricAmber,
      FareVerdict.lugi => MalateColors.hazardRed,
      FareVerdict.noFare => MalateColors.cyberCyan,
    };
    final verdictText = switch (r.verdict) {
      FareVerdict.sulit => 'SULIT!',
      FareVerdict.puwede => 'PUWEDE NA',
      FareVerdict.lugi => 'LUGI!',
      FareVerdict.noFare => '—',
    };
    final verdictIcon = switch (r.verdict) {
      FareVerdict.sulit => Icons.check_circle,
      FareVerdict.puwede => Icons.remove_circle,
      FareVerdict.lugi => Icons.cancel,
      FareVerdict.noFare => Icons.help_outline,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: verdictColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('VERDICT', verdictColor),
          const SizedBox(height: 16),

          // Fare input
          Row(
            children: [
              Text('Fare:', style: MalateTypography.bodyMedium),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _fareController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  style: MalateTypography.headlineSmall.copyWith(
                    color: MalateColors.neonMint,
                  ),
                  onChanged: (_) => _recalculate(),
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    prefixStyle: MalateTypography.headlineSmall.copyWith(
                      color: MalateColors.neonMint,
                    ),
                    hintText: '0',
                    hintStyle: MalateTypography.headlineSmall.copyWith(color: c.textMuted),
                    filled: true,
                    fillColor: c.gutter,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (r.verdict != FareVerdict.noFare) ...[
            const SizedBox(height: 20),

            // Verdict badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: verdictColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: verdictColor, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(verdictIcon, color: verdictColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      verdictText,
                      style: MalateTypography.headlineLarge.copyWith(
                        color: verdictColor,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Profit details
            _detailRow(
              c,
              'Net Profit',
              '₱${r.netProfit!.toStringAsFixed(2)}',
              valueColor: r.netProfit! >= 0 ? MalateColors.neonMint : MalateColors.hazardRed,
            ),
            Divider(color: c.sidewalk, height: 20),
            _detailRow(
              c,
              'Per Hour',
              '₱${r.earningsPerHour!.toStringAsFixed(0)}/hr',
              valueColor: verdictColor,
            ),

            const SizedBox(height: 12),
            Text(
              r.verdictReason,
              style: MalateTypography.bodySmall.copyWith(color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButtons(dynamic c) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (_pickup != null && _destination != null) {
                final nav = context.read<NavigationProvider>();
                nav.setRoute(from: _pickup!, to: _destination!);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const NavigationScreen()),
                );
              }
            },
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text('NAVIGATE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MalateColors.cyberCyan,
              foregroundColor: c.midnight,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 2,
      ),
    );
  }

  Widget _detailRow(dynamic c, String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: MalateTypography.bodySmall),
        Text(
          value,
          style: MalateTypography.headlineSmall.copyWith(
            fontSize: 14,
            color: valueColor ?? c.textPrimary,
          ),
        ),
      ],
    );
  }
}

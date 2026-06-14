import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../services/ride_logger.dart';

class FuelCalculatorScreen extends StatefulWidget {
  const FuelCalculatorScreen({super.key});

  @override
  State<FuelCalculatorScreen> createState() => _FuelCalculatorScreenState();
}

class _FuelCalculatorScreenState extends State<FuelCalculatorScreen> {
  final _distanceController = TextEditingController();
  final _gasPriceController = TextEditingController();
  final _efficiencyController = TextEditingController();
  final _fareController = TextEditingController();

  double _distanceKm = 0;
  double _gasPricePerLiter = 0;
  double _efficiencyKmPerLiter = 0;
  double _fareEarning = 0;

  bool _initialized = false;

  static const List<int> _quickDistances = [5, 10, 15, 20, 30, 50];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final logger = context.read<RideLogger>();
      _gasPricePerLiter = logger.fuelPricePerLiter;
      _efficiencyKmPerLiter = logger.vehicleKmPerLiter;

      _gasPriceController.text = _gasPricePerLiter.toStringAsFixed(0);
      _efficiencyController.text = _efficiencyKmPerLiter.toStringAsFixed(0);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _gasPriceController.dispose();
    _efficiencyController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  void _recalculate() {
    setState(() {
      _distanceKm = double.tryParse(_distanceController.text) ?? 0;
      _gasPricePerLiter = double.tryParse(_gasPriceController.text) ?? 0;
      _efficiencyKmPerLiter = double.tryParse(_efficiencyController.text) ?? 0;
      _fareEarning = double.tryParse(_fareController.text) ?? 0;
    });
  }

  double get _fuelLiters =>
      (_efficiencyKmPerLiter > 0 && _distanceKm > 0)
          ? _distanceKm / _efficiencyKmPerLiter
          : 0;

  double get _totalFuelCost => _fuelLiters * _gasPricePerLiter;

  double get _costPerKm =>
      _distanceKm > 0 ? _totalFuelCost / _distanceKm : 0;

  double get _netProfit => _fareEarning - _totalFuelCost;

  String _formatPeso(double amount) {
    final abs = amount.abs();
    final formatted = abs >= 1000
        ? '₱${abs.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}'
        : '₱${abs.toStringAsFixed(2)}';
    return amount < 0 ? '-$formatted' : formatted;
  }

  void _selectQuickDistance(int km) {
    _distanceController.text = km.toString();
    _recalculate();
  }

  InputDecoration _inputDecoration(BuildContext context, String label, String hint) {
    final c = MalateColors.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: MalateTypography.bodySmall.copyWith(color: c.textMuted),
      hintStyle: MalateTypography.bodySmall.copyWith(color: c.textMuted),
      filled: true,
      fillColor: c.gutter,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.sidewalk),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.sidewalk),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MalateColors.neonMint, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    return Scaffold(
      backgroundColor: c.midnight,
      appBar: AppBar(
        backgroundColor: c.midnight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FUEL CALCULATOR',
          style: MalateTypography.neonAccent(MalateColors.electricAmber),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _quickDistanceRow(context),
            const SizedBox(height: 16),
            _inputSection(context),
            const SizedBox(height: 16),
            _resultsSection(context),
            const SizedBox(height: 16),
            _routeCostSection(context),
          ],
        ),
      ),
    );
  }

  Widget _quickDistanceRow(BuildContext context) {
    final c = MalateColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK SELECT',
          style: MalateTypography.labelSmall.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickDistances.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final km = _quickDistances[i];
              final selected = _distanceController.text == km.toString();
              return GestureDetector(
                onTap: () => _selectQuickDistance(km),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? MalateColors.electricAmber.withValues(alpha: 0.15)
                        : c.asphalt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? MalateColors.electricAmber
                          : c.sidewalk,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '${km}km',
                    style: MalateTypography.labelSmall.copyWith(
                      color: selected
                          ? MalateColors.electricAmber
                          : c.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _inputSection(BuildContext context) {
    final c = MalateColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.sidewalk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined,
                  color: MalateColors.cyberCyan, size: 16),
              const SizedBox(width: 8),
              Text(
                'TRIP DETAILS',
                style: MalateTypography.neonAccent(MalateColors.cyberCyan)
                    .copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            style: MalateTypography.headlineSmall.copyWith(color: c.textPrimary),
            decoration: _inputDecoration(context, 'Trip Distance', '0')
                .copyWith(suffixText: 'km', suffixStyle: MalateTypography.bodySmall.copyWith(color: c.textMuted)),
            onChanged: (_) => _recalculate(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gasPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            style: MalateTypography.headlineSmall.copyWith(color: c.textPrimary),
            decoration: _inputDecoration(context, 'Gas Price per Liter', '65')
                .copyWith(prefixText: '₱ ', prefixStyle: MalateTypography.bodySmall.copyWith(color: c.textMuted), suffixText: '/L', suffixStyle: MalateTypography.bodySmall.copyWith(color: c.textMuted)),
            onChanged: (_) => _recalculate(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _efficiencyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            style: MalateTypography.headlineSmall.copyWith(color: c.textPrimary),
            decoration: _inputDecoration(context, 'Fuel Efficiency', '40')
                .copyWith(suffixText: 'km/L', suffixStyle: MalateTypography.bodySmall.copyWith(color: c.textMuted)),
            onChanged: (_) => _recalculate(),
          ),
        ],
      ),
    );
  }

  Widget _resultsSection(BuildContext context) {
    final c = MalateColors.of(context);
    final hasData = _distanceKm > 0 && _gasPricePerLiter > 0 && _efficiencyKmPerLiter > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData
              ? MalateColors.neonMint.withValues(alpha: 0.3)
              : c.sidewalk,
        ),
        boxShadow: hasData
            ? MalateColors.subtleGlow(MalateColors.neonMint)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_gas_station,
                  color: MalateColors.neonMint, size: 16),
              const SizedBox(width: 8),
              Text(
                'FUEL ESTIMATE',
                style: MalateTypography.neonAccent(MalateColors.neonMint)
                    .copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasData)
            Center(
              child: Text(
                'Enter trip details above',
                style: MalateTypography.bodySmall.copyWith(color: c.textMuted),
              ),
            )
          else ...[
            _resultRow(
              context,
              label: 'Fuel Needed',
              value: '${_fuelLiters.toStringAsFixed(2)} L',
              color: MalateColors.cyberCyan,
            ),
            Divider(color: c.sidewalk, height: 24),
            _resultRow(
              context,
              label: 'Total Fuel Cost',
              value: _formatPeso(_totalFuelCost),
              color: MalateColors.electricAmber,
              large: true,
            ),
            Divider(color: c.sidewalk, height: 24),
            _resultRow(
              context,
              label: 'Cost per km',
              value: '${_formatPeso(_costPerKm)}/km',
              color: c.textPrimary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(BuildContext context,
      {required String label,
      required String value,
      required Color color,
      bool large = false}) {
    final c = MalateColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: MalateTypography.bodyMedium.copyWith(color: c.textSecondary),
        ),
        Text(
          value,
          style: large
              ? MalateTypography.headlineLarge.copyWith(color: color)
              : MalateTypography.headlineSmall.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _routeCostSection(BuildContext context) {
    final c = MalateColors.of(context);
    final hasResults = _distanceKm > 0 && _gasPricePerLiter > 0 && _efficiencyKmPerLiter > 0;
    final hasFare = _fareEarning > 0;
    final isProfit = _netProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFare
              ? (isProfit
                  ? MalateColors.neonMint.withValues(alpha: 0.3)
                  : MalateColors.hazardRed.withValues(alpha: 0.3))
              : c.sidewalk,
        ),
        boxShadow: hasFare
            ? MalateColors.subtleGlow(
                isProfit ? MalateColors.neonMint : MalateColors.hazardRed)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: MalateColors.electricAmber, size: 16),
              const SizedBox(width: 8),
              Text(
                'ROUTE COST',
                style: MalateTypography.neonAccent(MalateColors.electricAmber)
                    .copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fareController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            style: MalateTypography.headlineSmall.copyWith(color: c.textPrimary),
            decoration: _inputDecoration(context, 'Fare / Estimated Earning', '0')
                .copyWith(
              prefixText: '₱ ',
              prefixStyle: MalateTypography.bodySmall.copyWith(color: c.textMuted),
            ),
            onChanged: (_) => _recalculate(),
          ),
          if (hasFare && hasResults) ...[
            const SizedBox(height: 20),
            _resultRow(
              context,
              label: 'Fare Earning',
              value: _formatPeso(_fareEarning),
              color: c.textPrimary,
            ),
            Divider(color: c.sidewalk, height: 20),
            _resultRow(
              context,
              label: 'Fuel Cost',
              value: '- ${_formatPeso(_totalFuelCost)}',
              color: MalateColors.electricAmber,
            ),
            Divider(color: c.sidewalk, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Profit',
                  style: MalateTypography.headlineSmall
                      .copyWith(color: c.textSecondary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isProfit
                            ? MalateColors.neonMint
                            : MalateColors.hazardRed)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isProfit
                          ? MalateColors.neonMint.withValues(alpha: 0.4)
                          : MalateColors.hazardRed.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _formatPeso(_netProfit),
                    style: MalateTypography.headlineLarge.copyWith(
                      color: isProfit
                          ? MalateColors.neonMint
                          : MalateColors.hazardRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                isProfit
                    ? 'Kumita ka ng ${_formatPeso(_netProfit)} pagkatapos ng gasolina!'
                    : 'Lugi ka ng ${_formatPeso(-_netProfit)} sa gasolina!',
                style: MalateTypography.bodySmall.copyWith(
                  color: isProfit ? MalateColors.neonMint : MalateColors.hazardRed,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ] else if (!hasResults && !hasFare) ...[
            const SizedBox(height: 12),
            Text(
              'Enter trip details and your fare to see net profit after fuel.',
              style: MalateTypography.bodySmall.copyWith(color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

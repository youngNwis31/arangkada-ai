class FareEstimateResult {
  final double distanceKm;
  final double durationMin;
  final double estimatedDurationMin;
  final double fuelLiters;
  final double fuelCost;
  final double costPerKm;
  final double? fareAmount;
  final double? netProfit;
  final double? earningsPerHour;
  final FareVerdict verdict;
  final String verdictReason;

  const FareEstimateResult({
    required this.distanceKm,
    required this.durationMin,
    required this.estimatedDurationMin,
    required this.fuelLiters,
    required this.fuelCost,
    required this.costPerKm,
    this.fareAmount,
    this.netProfit,
    this.earningsPerHour,
    required this.verdict,
    required this.verdictReason,
  });
}

enum FareVerdict { sulit, puwede, lugi, noFare }

class FareCalculator {
  FareCalculator._();

  static const double trafficBuffer = 1.3;

  static FareEstimateResult calculate({
    required double distanceKm,
    required double durationMin,
    required double fuelPricePerLiter,
    required double kmPerLiter,
    double? fareAmount,
    double hourlyTarget = 100.0,
  }) {
    final fuelLiters = kmPerLiter > 0 ? distanceKm / kmPerLiter : 0.0;
    final fuelCost = fuelLiters * fuelPricePerLiter;
    final costPerKm = distanceKm > 0 ? fuelCost / distanceKm : 0.0;
    final estimatedDuration = durationMin * trafficBuffer;

    if (fareAmount == null || fareAmount <= 0) {
      return FareEstimateResult(
        distanceKm: distanceKm,
        durationMin: durationMin,
        estimatedDurationMin: estimatedDuration,
        fuelLiters: fuelLiters,
        fuelCost: fuelCost,
        costPerKm: costPerKm,
        verdict: FareVerdict.noFare,
        verdictReason: 'Enter fare amount to see verdict',
      );
    }

    final netProfit = fareAmount - fuelCost;
    final hours = estimatedDuration / 60;
    final earningsPerHour = hours > 0 ? netProfit / hours : 0.0;

    FareVerdict verdict;
    String reason;

    if (earningsPerHour >= hourlyTarget) {
      verdict = FareVerdict.sulit;
      reason = '₱${earningsPerHour.toStringAsFixed(0)}/hr — above your ₱${hourlyTarget.toStringAsFixed(0)}/hr target';
    } else if (earningsPerHour >= hourlyTarget * 0.7) {
      verdict = FareVerdict.puwede;
      reason = '₱${earningsPerHour.toStringAsFixed(0)}/hr — close to your ₱${hourlyTarget.toStringAsFixed(0)}/hr target';
    } else {
      verdict = FareVerdict.lugi;
      reason = '₱${earningsPerHour.toStringAsFixed(0)}/hr — below your ₱${hourlyTarget.toStringAsFixed(0)}/hr target';
    }

    return FareEstimateResult(
      distanceKm: distanceKm,
      durationMin: durationMin,
      estimatedDurationMin: estimatedDuration,
      fuelLiters: fuelLiters,
      fuelCost: fuelCost,
      costPerKm: costPerKm,
      fareAmount: fareAmount,
      netProfit: netProfit,
      earningsPerHour: earningsPerHour,
      verdict: verdict,
      verdictReason: reason,
    );
  }
}

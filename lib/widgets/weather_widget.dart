import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherService>(
      builder: (context, weather, _) {
        if (!weather.hasData && !weather.isLoading) {
          return const SizedBox.shrink();
        }
        if (weather.isLoading && !weather.hasData) {
          return _loadingChip(context);
        }
        return _weatherCard(context, weather);
      },
    );
  }

  Widget _loadingChip(BuildContext context) {
    final c = MalateColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.asphalt.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.sidewalk),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: MalateColors.cyberCyan,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading weather...',
            style: MalateTypography.labelSmall.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _weatherCard(BuildContext context, WeatherService weather) {
    final c = MalateColors.of(context);
    final data = weather.currentWeather!;
    final isRaining = data.isRaining;
    final isFloodRisk = weather.isFloodRisk;

    final borderColor = isFloodRisk
        ? MalateColors.hazardRed
        : isRaining
            ? MalateColors.cyberCyan
            : c.sidewalk;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.asphalt.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withValues(alpha: isFloodRisk ? 0.8 : 0.5),
        ),
        boxShadow: isFloodRisk
            ? MalateColors.subtleGlow(MalateColors.hazardRed)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: _iconColor(data), size: 18),
          const SizedBox(width: 6),
          Text(
            '${data.temperature.round()}°',
            style: MalateTypography.headlineSmall.copyWith(
              color: c.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              data.description,
              style: MalateTypography.labelSmall.copyWith(
                color: c.textSecondary,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (data.rainMm > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: MalateColors.cyberCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${data.rainMm.toStringAsFixed(1)}mm',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: MalateColors.cyberCyan,
                ),
              ),
            ),
          ],
          if (isFloodRisk) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: MalateColors.hazardRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FLOOD RISK',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: MalateColors.hazardRed,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          if (weather.fromCache) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: c.gutter,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'CACHED',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: c.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _iconColor(WeatherData data) {
    if (data.isHeavyRain) return MalateColors.hazardRed;
    if (data.isRaining) return MalateColors.cyberCyan;
    if (data.weatherCode == 0) return MalateColors.electricAmber;
    return MalateColors.neonMint;
  }
}

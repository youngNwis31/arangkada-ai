import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../core/offline/tile_cache_manager.dart';

class OfflineMapsScreen extends StatelessWidget {
  const OfflineMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    final cache = context.watch<TileCacheManager>();

    return Scaffold(
      backgroundColor: c.midnight,
      appBar: AppBar(
        backgroundColor: c.midnight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'OFFLINE MAPS',
          style: MalateTypography.labelLarge.copyWith(
            color: MalateColors.cyberCyan,
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
            // Map preview
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.gutter, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(14.565, 121.0),
                  initialZoom: 10.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConfig.osmTileUrl,
                    userAgentPackageName: 'com.arangkada.arangkadaAi',
                    maxZoom: 19,
                    tileProvider: cache.isInitialized
                        ? cache.tileProvider
                        : null,
                  ),
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: [
                          LatLng(AppConfig.metroManilaMinLat,
                              AppConfig.metroManilaMinLng),
                          LatLng(AppConfig.metroManilaMaxLat,
                              AppConfig.metroManilaMinLng),
                          LatLng(AppConfig.metroManilaMaxLat,
                              AppConfig.metroManilaMaxLng),
                          LatLng(AppConfig.metroManilaMinLat,
                              AppConfig.metroManilaMaxLng),
                        ],
                        color: MalateColors.cyberCyan.withValues(alpha: 0.15),
                        borderColor: MalateColors.cyberCyan,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Region info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.asphalt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.gutter, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: MalateColors.cyberCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.map,
                            color: MalateColors.cyberCyan, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Metro Manila',
                              style: MalateTypography.bodyLarge.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'All 16 cities • Zoom 13-15',
                              style: MalateTypography.bodySmall
                                  .copyWith(color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (cache.hasDownload)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MalateColors.neonMint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'SAVED',
                            style: MalateTypography.bodySmall.copyWith(
                              color: MalateColors.neonMint,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _statItem(
                        c,
                        Icons.grid_view,
                        '${_formatNumber(cache.storeTileCount)} tiles',
                      ),
                      const SizedBox(width: 16),
                      _statItem(
                        c,
                        Icons.storage,
                        '${cache.storeSizeMB.toStringAsFixed(1)} MB',
                      ),
                      const SizedBox(width: 16),
                      _statItem(
                        c,
                        Icons.zoom_in,
                        'Street level',
                      ),
                    ],
                  ),

                  if (cache.isDownloading) ...[
                    const SizedBox(height: 20),
                    _downloadProgress(c, cache),
                  ],

                  const SizedBox(height: 20),

                  // Action buttons
                  if (cache.isDownloading)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => cache.cancelDownload(),
                        icon: const Icon(Icons.stop, size: 18),
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
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => cache.downloadMetroManila(),
                            icon: Icon(
                              cache.hasDownload
                                  ? Icons.refresh
                                  : Icons.download,
                              size: 18,
                            ),
                            label: Text(
                              cache.hasDownload ? 'UPDATE' : 'DOWNLOAD',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MalateColors.cyberCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (cache.hasDownload) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(context, cache),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('DELETE'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MalateColors.hazardRed,
                                side: const BorderSide(
                                    color: MalateColors.hazardRed),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.asphalt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.gutter, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOW IT WORKS',
                    style: MalateTypography.bodySmall.copyWith(
                      color: MalateColors.cyberCyan,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(c, Icons.wifi, 'Download on WiFi, use anywhere'),
                  const SizedBox(height: 8),
                  _infoRow(c, Icons.map, 'Maps load from cache when offline'),
                  const SizedBox(height: 8),
                  _infoRow(c, Icons.explore,
                      'Areas you browse are auto-cached too'),
                  const SizedBox(height: 8),
                  _infoRow(c, Icons.route,
                      'Cached routes still work without signal'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(dynamic c, IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: MalateTypography.bodySmall.copyWith(color: c.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadProgress(dynamic c, TileCacheManager cache) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Downloading...',
              style: MalateTypography.bodySmall.copyWith(
                color: MalateColors.cyberCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(cache.progress * 100).toStringAsFixed(1)}%',
              style: MalateTypography.bodySmall.copyWith(
                color: MalateColors.cyberCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: cache.progress,
            backgroundColor: c.gutter,
            valueColor: const AlwaysStoppedAnimation(MalateColors.cyberCyan),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_formatNumber(cache.downloadedTiles)} / ${_formatNumber(cache.totalTiles)} tiles',
          style: MalateTypography.bodySmall.copyWith(color: c.textMuted),
        ),
      ],
    );
  }

  Widget _infoRow(dynamic c, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MalateColors.neonMint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: MalateTypography.bodySmall.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, TileCacheManager cache) {
    final c = MalateColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.asphalt,
        title: Text('Delete Map Cache?',
            style: TextStyle(color: c.textPrimary)),
        content: Text(
          'This will remove ${cache.storeSizeMB.toStringAsFixed(1)} MB of downloaded map tiles. '
          'You\'ll need WiFi to download them again.',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              cache.deleteCache();
              Navigator.pop(ctx);
            },
            child: const Text('DELETE',
                style: TextStyle(color: MalateColors.hazardRed)),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

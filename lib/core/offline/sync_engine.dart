import 'package:flutter/foundation.dart';
import '../database/local_database.dart';
import 'connectivity_monitor.dart';

class SyncEngine {
  final ConnectivityMonitor connectivity;
  bool _isSyncing = false;

  SyncEngine({required this.connectivity}) {
    connectivity.onReconnect(_onReconnected);
  }

  void _onReconnected() {
    syncAll();
  }

  Future<void> syncAll() async {
    if (_isSyncing || connectivity.isOffline) return;
    _isSyncing = true;

    try {
      await _syncHazardReports();
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncHazardReports() async {
    final unsynced = await LocalDatabase.getUnsyncedHazards();
    if (unsynced.isEmpty) return;

    // When Firebase is configured, this uploads to Firestore.
    // For now, just mark them as synced locally.
    final ids = unsynced.map((h) => h['id'] as String).toList();
    await LocalDatabase.markHazardsSynced(ids);
    debugPrint('Synced ${ids.length} hazard reports');
  }
}

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityMonitor extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = false;
  ConnectivityResult _currentType = ConnectivityResult.none;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  ConnectivityResult get connectionType => _currentType;

  String get statusText {
    if (!_isOnline) return 'OFFLINE';
    switch (_currentType) {
      case ConnectivityResult.wifi:
        return 'WI-FI';
      case ConnectivityResult.mobile:
        return 'MOBILE DATA';
      default:
        return 'ONLINE';
    }
  }

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _update(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final result =
        results.isNotEmpty ? results.first : ConnectivityResult.none;
    final wasOffline = !_isOnline;
    _currentType = result;
    _isOnline = result != ConnectivityResult.none;

    if (wasOffline && _isOnline) {
      _onReconnected();
    }

    notifyListeners();
  }

  final List<VoidCallback> _reconnectCallbacks = [];

  void onReconnect(VoidCallback callback) {
    _reconnectCallbacks.add(callback);
  }

  void _onReconnected() {
    for (final cb in _reconnectCallbacks) {
      cb();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

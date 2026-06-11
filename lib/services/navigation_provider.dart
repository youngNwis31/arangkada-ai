import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import 'location_service.dart';
import 'mapbox_service.dart';
import 'offline_nav_engine.dart';

class NavigationProvider extends ChangeNotifier {
  LocationModel? _currentLocation;
  LocationModel? _destination;
  List<RouteModel> _routes = [];
  int _selectedRouteIndex = 0;
  bool _isLoading = false;
  String? _error;

  final OfflineNavEngine navEngine = OfflineNavEngine();

  LocationModel? get currentLocation => _currentLocation;
  LocationModel? get destination => _destination;
  List<RouteModel> get routes => _routes;
  int get selectedRouteIndex => _selectedRouteIndex;
  RouteModel? get selectedRoute =>
      _routes.isNotEmpty ? _routes[_selectedRouteIndex] : null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasRoute => _routes.isNotEmpty;
  bool get isNavigating => navEngine.isNavigating;

  Future<void> initLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentLocation = await LocationService.getCurrentLocation();
    } catch (e) {
      _error = 'Location unavailable';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setDestination(LocationModel location) {
    _destination = location;
    notifyListeners();
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    if (_currentLocation == null || _destination == null) return;

    _isLoading = true;
    _error = null;
    _routes = [];
    _selectedRouteIndex = 0;
    notifyListeners();

    try {
      _routes = await MapboxService.getRoutes(
        origin: _currentLocation!,
        destination: _destination!,
      );
      if (_routes.isEmpty) _error = 'No routes found';
    } catch (e) {
      _error = 'Route fetch failed — check connection';
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectRoute(int index) {
    if (index >= 0 && index < _routes.length) {
      _selectedRouteIndex = index;
      notifyListeners();
    }
  }

  Future<void> startNavigation() async {
    if (selectedRoute == null) return;
    await navEngine.startNavigation(selectedRoute!);
    notifyListeners();
    navEngine.addListener(_onNavEngineUpdate);
  }

  void stopNavigation() {
    navEngine.removeListener(_onNavEngineUpdate);
    navEngine.stopNavigation();
    notifyListeners();
  }

  void _onNavEngineUpdate() {
    notifyListeners();
  }

  void clearRoute() {
    if (isNavigating) stopNavigation();
    _destination = null;
    _routes = [];
    _selectedRouteIndex = 0;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    navEngine.removeListener(_onNavEngineUpdate);
    navEngine.dispose();
    super.dispose();
  }
}

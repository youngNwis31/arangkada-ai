import 'package:flutter/foundation.dart';
import '../../models/hazard_report.dart';
import '../../services/hazard_service.dart';
import '../../services/navigation_provider.dart';

class NavigationViewModel extends ChangeNotifier {
  final NavigationProvider _navProvider;

  List<HazardReport> floodReports = [];
  bool showFloodBanner = false;

  NavigationViewModel(this._navProvider);

  NavigationProvider get nav => _navProvider;

  Future<void> checkFloodZones() async {
    final route = _navProvider.selectedRoute;
    if (route == null) return;

    final floods =
        await HazardService.getFloodReportsAlongRoute(route.coordinates);
    if (floods.isNotEmpty) {
      floodReports = floods;
      showFloodBanner = true;
      notifyListeners();

      Future.delayed(const Duration(seconds: 8), () {
        showFloodBanner = false;
        notifyListeners();
      });
    }
  }

  void dismissFloodBanner() {
    showFloodBanner = false;
    notifyListeners();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../core/offline/connectivity_monitor.dart';
import '../models/location_model.dart';
import '../services/mapbox_service.dart';
import '../services/poi_service.dart';

const _suggestions = <LocationModel>[
  LocationModel(latitude: 14.5547, longitude: 121.0244, name: 'Makati', address: 'Business district, Metro Manila'),
  LocationModel(latitude: 14.5176, longitude: 121.0509, name: 'BGC Taguig', address: 'Bonifacio Global City'),
  LocationModel(latitude: 14.6760, longitude: 121.0437, name: 'Quezon City', address: 'Largest city in Metro Manila'),
  LocationModel(latitude: 14.5764, longitude: 121.0851, name: 'Ortigas Pasig', address: 'Ortigas Center, Pasig'),
  LocationModel(latitude: 14.5378, longitude: 121.0014, name: 'Pasay MOA', address: 'Mall of Asia area'),
  LocationModel(latitude: 16.4023, longitude: 120.5960, name: 'Baguio', address: 'Summer Capital of the Philippines'),
];

const _nearbyCategories = <(PoiCategory, IconData, Color)>[
  (PoiCategory.cafe, Icons.coffee, Color(0xFF8B5CF6)),
  (PoiCategory.restaurant, Icons.restaurant, Color(0xFFFF6B35)),
  (PoiCategory.fastFood, Icons.fastfood, Color(0xFFFFB800)),
  (PoiCategory.gasStation, Icons.local_gas_station, MalateColors.electricAmber),
  (PoiCategory.bank, Icons.account_balance, Color(0xFF4A90D9)),
  (PoiCategory.pharmacy, Icons.local_pharmacy, MalateColors.hazardRed),
  (PoiCategory.convenience, Icons.storefront, MalateColors.cyberCyan),
  (PoiCategory.hospital, Icons.local_hospital, Color(0xFFE53E3E)),
  (PoiCategory.parking, Icons.local_parking, Color(0xFF8B5CF6)),
];

class SearchScreen extends StatefulWidget {
  final LocationModel? currentLocation;
  const SearchScreen({super.key, this.currentLocation});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();

  LocationModel? _selectedOrigin;
  LocationModel? _selectedDestination;

  List<LocationModel> _results = [];
  bool _searching = false;
  bool _hasActiveQuery = false;
  Timer? _debounce;
  bool _editingFrom = false;
  String? _browsingCategory;
  bool _isOfflineResults = false;

  String get _activeQuery =>
      _editingFrom ? _fromController.text : _toController.text;

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      _selectedOrigin = widget.currentLocation;
      _fromController.text = widget.currentLocation!.name ?? 'Your location';
    } else {
      _fromController.text = 'Your location';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _searching = false;
        _hasActiveQuery = false;
      });
      return;
    }
    setState(() => _hasActiveQuery = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) return;
    setState(() => _searching = true);
    final isOffline = !context.read<ConnectivityMonitor>().isOnline;
    try {
      final r = await MapboxService.searchPlaces(
        q,
        proximityLng: widget.currentLocation?.longitude,
        proximityLat: widget.currentLocation?.latitude,
      );
      if (mounted) {
        setState(() {
          _results = r;
          _searching = false;
          _isOfflineResults = isOffline;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _browseCategory(PoiCategory category) async {
    setState(() {
      _searching = true;
      _browsingCategory = category.label;
      _hasActiveQuery = true;
    });
    try {
      final lat = widget.currentLocation?.latitude ?? 14.5995;
      final lng = widget.currentLocation?.longitude ?? 120.9842;
      final results = await PoiService.fetchByCategory(
        lat: lat,
        lng: lng,
        category: category,
        radius: 3000,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectLocation(LocationModel loc) {
    if (_editingFrom) {
      _selectedOrigin = loc;
      _fromController.text = loc.name ?? loc.address ?? 'Selected';
      _fromFocus.unfocus();
      setState(() {
        _results = [];
        _hasActiveQuery = false;
        _editingFrom = false;
      });
      if (_selectedDestination == null) {
        _toFocus.requestFocus();
      } else {
        _navigateBack();
      }
    } else {
      _selectedDestination = loc;
      _toController.text = loc.name ?? loc.address ?? 'Selected';
      _toFocus.unfocus();
      setState(() {
        _results = [];
        _hasActiveQuery = false;
      });
      _navigateBack();
    }
  }

  void _navigateBack() {
    if (_selectedDestination == null) return;
    final result = <String, dynamic>{
      'location': _selectedDestination!,
    };
    if (_selectedOrigin != null) {
      result['origin'] = _selectedOrigin!;
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);

    Widget body;
    if (_searching) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
              color: MalateColors.neonMint, strokeWidth: 2),
        ),
      );
    } else if (_results.isNotEmpty) {
      body = _searchResultsList();
    } else if (_browsingCategory != null) {
      body = _noResults();
    } else if (_hasActiveQuery && _activeQuery.trim().length >= 2) {
      body = _noResults();
    } else {
      body = _suggestionsList();
    }

    return Scaffold(
      backgroundColor: c.midnight,
      appBar: AppBar(
        backgroundColor: c.midnight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SET ROUTE',
            style: MalateTypography.neonAccent(MalateColors.cyberCyan)),
      ),
      body: Column(
        children: [
          _routeFields(),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _routeFields() {
    final c = MalateColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.sidewalk),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: MalateColors.neonMint,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Container(
                  width: 2, height: 32,
                  color: c.textMuted.withValues(alpha: 0.3),
                ),
                const Icon(Icons.location_on, color: MalateColors.hazardRed, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _buildField(
                  controller: _fromController,
                  focusNode: _fromFocus,
                  hint: 'From where?',
                  onTap: () {
                    setState(() => _editingFrom = true);
                    _fromController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _fromController.text.length,
                    );
                  },
                  onChanged: (q) {
                    _editingFrom = true;
                    _onChanged(q);
                  },
                  onClear: () {
                    _fromController.text = 'Your location';
                    _selectedOrigin = widget.currentLocation;
                    setState(() {
                      _results = [];
                      _hasActiveQuery = false;
                    });
                  },
                  showClear: _fromController.text.isNotEmpty &&
                      _fromController.text != 'Your location',
                ),
                const SizedBox(height: 8),
                _buildField(
                  controller: _toController,
                  focusNode: _toFocus,
                  hint: 'Where to, rider?',
                  onTap: () => setState(() => _editingFrom = false),
                  onChanged: (q) {
                    _editingFrom = false;
                    _onChanged(q);
                  },
                  onClear: () {
                    _toController.clear();
                    _selectedDestination = null;
                    setState(() {
                      _results = [];
                      _hasActiveQuery = false;
                    });
                  },
                  showClear: _toController.text.isNotEmpty,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required VoidCallback onTap,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
    required bool showClear,
  }) {
    final c = MalateColors.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onTap: onTap,
      onChanged: onChanged,
      autocorrect: false,
      enableSuggestions: false,
      style: MalateTypography.bodyMedium.copyWith(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: MalateTypography.bodyMedium.copyWith(color: c.textMuted),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: c.gutter,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: showClear
            ? IconButton(
                icon: Icon(Icons.clear, size: 16, color: c.textMuted),
                onPressed: onClear,
              )
            : null,
      ),
    );
  }

  Widget _searchResultsList() {
    final c = MalateColors.of(context);
    final label = _browsingCategory != null
        ? 'NEARBY ${_browsingCategory!.toUpperCase()}'
        : _editingFrom
            ? 'SET AS ORIGIN'
            : 'SET AS DESTINATION';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Text(label,
                  style: MalateTypography.neonAccent(c.textMuted)
                      .copyWith(fontSize: 11)),
              const Spacer(),
              if (_browsingCategory != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _results = [];
                      _hasActiveQuery = false;
                      _browsingCategory = null;
                    });
                  },
                  child: Text('BACK',
                      style: MalateTypography.labelSmall
                          .copyWith(color: MalateColors.cyberCyan, fontSize: 11)),
                ),
              if (_isOfflineResults)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: MalateColors.electricAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('OFFLINE',
                      style: MalateTypography.labelSmall.copyWith(
                          color: MalateColors.electricAmber,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              Text(' ${_results.length} found',
                  style: MalateTypography.labelSmall
                      .copyWith(color: c.textDisabled, fontSize: 10)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _results.length,
            separatorBuilder: (_, __) =>
                Divider(color: c.sidewalk, indent: 64),
            itemBuilder: (_, i) => _locationTile(_results[i]),
          ),
        ),
      ],
    );
  }

  Widget _noResults() {
    final c = MalateColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: c.textDisabled),
          const SizedBox(height: 12),
          Text('Walang nakita',
              style: MalateTypography.headlineSmall
                  .copyWith(color: c.textMuted)),
          const SizedBox(height: 6),
          Text('Try a street name, landmark, or barangay',
              style: MalateTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _suggestionsList() {
    final c = MalateColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'EXPLORE NEARBY',
            style: MalateTypography.neonAccent(c.textMuted)
                .copyWith(fontSize: 11),
          ),
        ),
        _nearbyGrid(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'POPULAR DESTINATIONS',
            style: MalateTypography.neonAccent(c.textMuted)
                .copyWith(fontSize: 11),
          ),
        ),
        ..._suggestions.map((loc) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _locationTile(loc),
            )),
      ],
    );
  }

  Widget _nearbyGrid() {
    final c = MalateColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _nearbyCategories.map((cat) {
        final (category, icon, color) = cat;
        return GestureDetector(
          onTap: () => _browseCategory(category),
          child: Container(
            width: (MediaQuery.of(context).size.width - 56) / 3,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: c.asphalt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  category.label,
                  style: MalateTypography.labelSmall.copyWith(
                    color: c.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _locationTile(LocationModel place) {
    final c = MalateColors.of(context);
    final icon = _placeIcon(place.placeType);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: MalateColors.neonMint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: MalateColors.neonMint, size: 20),
      ),
      title: Text(
        place.name ?? 'Unknown',
        style: MalateTypography.headlineSmall
            .copyWith(fontSize: 14, color: c.textPrimary),
      ),
      subtitle: place.address != null
          ? Text(
              place.address!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MalateTypography.bodySmall,
            )
          : null,
      onTap: () => _selectLocation(place),
    );
  }

  IconData _placeIcon(String? type) {
    return switch (type) {
      'food' => Icons.restaurant,
      'health' => Icons.local_hospital,
      'education' => Icons.school,
      'finance' => Icons.account_balance,
      'worship' => Icons.church,
      'fuel' => Icons.local_gas_station,
      'emergency' => Icons.local_police,
      'shop' => Icons.storefront,
      'landmark' => Icons.photo_camera,
      'building' => Icons.business,
      'road' => Icons.add_road,
      'office' => Icons.work,
      'transport' => Icons.directions_bus,
      'amenity' => Icons.place,
      _ => Icons.location_on,
    };
  }
}

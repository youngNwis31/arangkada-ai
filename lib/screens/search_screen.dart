import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/location_model.dart';
import '../services/mapbox_service.dart';

const _suggestions = <LocationModel>[
  LocationModel(latitude: 14.5547, longitude: 121.0244, name: 'Makati', address: 'Business district, Metro Manila'),
  LocationModel(latitude: 14.5176, longitude: 121.0509, name: 'BGC Taguig', address: 'Bonifacio Global City'),
  LocationModel(latitude: 14.6760, longitude: 121.0437, name: 'Quezon City', address: 'Largest city in Metro Manila'),
  LocationModel(latitude: 14.5764, longitude: 121.0851, name: 'Ortigas Pasig', address: 'Ortigas Center, Pasig'),
  LocationModel(latitude: 14.5378, longitude: 121.0014, name: 'Pasay MOA', address: 'Mall of Asia area'),
  LocationModel(latitude: 16.4023, longitude: 120.5960, name: 'Baguio', address: 'Summer Capital of the Philippines'),
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
  Timer? _debounce;
  bool _editingFrom = false;

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
      setState(() { _results = []; _searching = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final r = await MapboxService.searchPlaces(
        q,
        proximityLng: widget.currentLocation?.longitude,
        proximityLat: widget.currentLocation?.latitude,
      );
      if (mounted) setState(() { _results = r; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectLocation(LocationModel loc) {
    if (_editingFrom) {
      _selectedOrigin = loc;
      _fromController.text = loc.name ?? loc.address ?? 'Selected';
      _fromFocus.unfocus();
      setState(() { _results = []; _editingFrom = false; });
      if (_selectedDestination == null) {
        _toFocus.requestFocus();
      } else {
        _navigateBack();
      }
    } else {
      _selectedDestination = loc;
      _toController.text = loc.name ?? loc.address ?? 'Selected';
      _toFocus.unfocus();
      setState(() => _results = []);
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
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                  color: MalateColors.neonMint, strokeWidth: 2),
            ),
          Expanded(
            child: _results.isNotEmpty
                ? _searchResultsList()
                : (_toController.text.isNotEmpty && _results.isEmpty && !_searching)
                    ? _noResults()
                    : _suggestionsList(),
          ),
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
                Icon(Icons.location_on, color: MalateColors.hazardRed, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _fromController,
                  focusNode: _fromFocus,
                  onTap: () => setState(() => _editingFrom = true),
                  onChanged: (q) {
                    _editingFrom = true;
                    _onChanged(q);
                  },
                  style: MalateTypography.bodyMedium
                      .copyWith(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'From where?',
                    hintStyle: MalateTypography.bodyMedium
                        .copyWith(color: c.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: c.gutter,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _fromController.text.isNotEmpty &&
                            _fromController.text != 'Your location'
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 16, color: c.textMuted),
                            onPressed: () {
                              _fromController.text = 'Your location';
                              _selectedOrigin = widget.currentLocation;
                              setState(() => _results = []);
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _toController,
                  focusNode: _toFocus,
                  onTap: () => setState(() => _editingFrom = false),
                  onChanged: (q) {
                    _editingFrom = false;
                    _onChanged(q);
                  },
                  style: MalateTypography.bodyMedium
                      .copyWith(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Where to, rider?',
                    hintStyle: MalateTypography.bodyMedium
                        .copyWith(color: c.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: c.gutter,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _toController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 16, color: c.textMuted),
                            onPressed: () {
                              _toController.clear();
                              _selectedDestination = null;
                              setState(() => _results = []);
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchResultsList() {
    final c = MalateColors.of(context);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, __) =>
          Divider(color: c.sidewalk, indent: 72),
      itemBuilder: (_, i) => _locationTile(_results[i]),
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
          Text('Try searching for a street, landmark, or city',
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

  Widget _locationTile(LocationModel place) {
    final c = MalateColors.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: MalateColors.neonMint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.location_on,
            color: MalateColors.neonMint, size: 20),
      ),
      title: Text(
        place.name ?? 'Unknown',
        style: MalateTypography.headlineSmall
            .copyWith(fontSize: 14, color: c.textPrimary),
      ),
      subtitle: place.address != null
          ? Text(
              place.address!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MalateTypography.bodySmall,
            )
          : null,
      onTap: () => _selectLocation(place),
    );
  }
}

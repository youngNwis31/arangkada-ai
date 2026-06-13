import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/location_model.dart';
import '../services/mapbox_service.dart';

const _luzonPresets = <_CityGroup>[
  _CityGroup('METRO MANILA', [
    _City('Manila', 14.5995, 120.9842, 'Capital of the Philippines'),
    _City('Quezon City', 14.6760, 121.0437, 'Largest city in Metro Manila'),
    _City('Makati', 14.5547, 121.0244, 'Business district'),
    _City('Taguig (BGC)', 14.5176, 121.0509, 'Bonifacio Global City'),
    _City('Pasig', 14.5764, 121.0851, 'Ortigas Center'),
    _City('Mandaluyong', 14.5794, 121.0359, 'Shopping capital'),
    _City('Pasay', 14.5378, 121.0014, 'MOA, NAIA area'),
    _City('Parañaque', 14.4793, 121.0198, 'Entertainment City'),
    _City('Las Piñas', 14.4445, 120.9939, 'South Metro Manila'),
    _City('Muntinlupa', 14.4081, 121.0415, 'Alabang, Filinvest'),
    _City('Marikina', 14.6507, 121.1029, 'Shoe capital'),
    _City('Caloocan', 14.6488, 120.9840, 'North Metro Manila'),
    _City('Valenzuela', 14.6942, 120.9608, 'Industrial city'),
    _City('San Juan', 14.6019, 121.0355, 'Smallest city'),
    _City('Navotas', 14.6617, 120.9417, 'Fish port'),
    _City('Malabon', 14.6625, 120.9575, 'Heritage city'),
  ]),
  _CityGroup('CENTRAL LUZON', [
    _City('Angeles City', 15.1450, 120.5887, 'Clark, Pampanga'),
    _City('San Fernando', 15.0286, 120.6882, 'Capital of Pampanga'),
    _City('Olongapo', 14.8292, 120.2828, 'Subic Bay area'),
    _City('Tarlac City', 15.4365, 120.5966, 'Tarlac province'),
    _City('Cabanatuan', 15.4869, 120.9681, 'Nueva Ecija'),
    _City('Malolos', 14.8433, 120.8114, 'Capital of Bulacan'),
    _City('Meycauayan', 14.7371, 120.9607, 'Bulacan'),
    _City('Balanga', 14.6762, 120.5362, 'Capital of Bataan'),
  ]),
  _CityGroup('CALABARZON', [
    _City('Antipolo', 14.5860, 121.1761, 'Rizal province'),
    _City('Calamba', 14.2114, 121.1653, 'Laguna, birthplace of Rizal'),
    _City('Batangas City', 13.7565, 121.0583, 'Port city'),
    _City('Lipa', 13.9411, 121.1625, 'Batangas'),
    _City('Lucena', 13.9373, 121.6170, 'Quezon province'),
    _City('San Pablo', 14.0685, 121.3254, 'City of Seven Lakes'),
    _City('Dasmariñas', 14.3294, 120.9367, 'Cavite'),
    _City('Bacoor', 14.4624, 120.9645, 'Cavite'),
    _City('Imus', 14.4297, 120.9368, 'Cavite'),
    _City('Santa Rosa', 14.3122, 121.1115, 'Laguna, Enchanted Kingdom'),
    _City('Biñan', 14.3346, 121.0813, 'Laguna'),
    _City('Cavite City', 14.4836, 120.8956, 'Historical city'),
  ]),
  _CityGroup('ILOCOS REGION', [
    _City('Laoag', 18.1979, 120.5936, 'Ilocos Norte'),
    _City('Vigan', 17.5747, 120.3869, 'Heritage city, Ilocos Sur'),
    _City('San Fernando', 16.6159, 120.3209, 'La Union, surfing capital'),
    _City('Dagupan', 16.0433, 120.3374, 'Pangasinan'),
    _City('Alaminos', 16.1554, 119.9811, 'Hundred Islands'),
    _City('Urdaneta', 15.9762, 120.5712, 'Pangasinan'),
  ]),
  _CityGroup('CORDILLERA', [
    _City('Baguio', 16.4023, 120.5960, 'Summer Capital of the PH'),
    _City('La Trinidad', 16.4564, 120.5870, 'Strawberry capital, Benguet'),
    _City('Tabuk', 17.4189, 121.4443, 'Kalinga province'),
    _City('Bontoc', 17.0874, 120.9778, 'Mountain Province'),
  ]),
  _CityGroup('CAGAYAN VALLEY', [
    _City('Tuguegarao', 17.6132, 121.7270, 'Hottest city in PH'),
    _City('Santiago', 16.6892, 121.5487, 'Isabela'),
    _City('Cauayan', 16.9315, 121.7731, 'Isabela'),
    _City('Ilagan', 17.1485, 121.8892, 'Capital of Isabela'),
  ]),
  _CityGroup('BICOL REGION', [
    _City('Naga', 13.6192, 123.1814, 'CamSur, Peñafrancia'),
    _City('Legazpi', 13.1391, 123.7438, 'Mayon Volcano view'),
    _City('Sorsogon City', 12.9742, 124.0049, 'Whale shark watching'),
    _City('Daet', 14.1122, 122.9553, 'Camarines Norte, surfing'),
    _City('Tabaco', 13.3587, 123.7345, 'Albay'),
    _City('Iriga', 13.4213, 123.4116, 'CamSur'),
  ]),
];

class _CityGroup {
  final String region;
  final List<_City> cities;
  const _CityGroup(this.region, this.cities);
}

class _City {
  final String name;
  final double lat;
  final double lng;
  final String subtitle;
  const _City(this.name, this.lat, this.lng, this.subtitle);

  LocationModel toLocation() => LocationModel(
        latitude: lat,
        longitude: lng,
        name: name,
        address: subtitle,
      );
}

class SearchScreen extends StatefulWidget {
  final LocationModel? currentLocation;
  const SearchScreen({super.key, this.currentLocation});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<LocationModel> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
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
    Navigator.pop(context, {'location': loc});
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
        title: Text('SET DESTINATION',
            style: MalateTypography.neonAccent(MalateColors.cyberCyan)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: _onChanged,
              style: MalateTypography.bodyLarge.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search places in Luzon...',
                prefixIcon: const Icon(Icons.location_on,
                    color: MalateColors.neonMint),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: c.textMuted, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                  color: MalateColors.neonMint, strokeWidth: 2),
            ),
          Expanded(
            child: _controller.text.isNotEmpty || _results.isNotEmpty
                ? _searchResults()
                : _presetsList(),
          ),
        ],
      ),
    );
  }

  Widget _searchResults() {
    final c = MalateColors.of(context);
    if (_results.isEmpty && !_searching) {
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
            Text('Try a different search or pick from the list',
                style: MalateTypography.bodySmall),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(color: c.sidewalk),
      itemBuilder: (_, i) => _locationTile(_results[i]),
    );
  }

  Widget _presetsList() {
    final c = MalateColors.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: _luzonPresets.length,
      itemBuilder: (_, groupIndex) {
        final group = _luzonPresets[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIndex > 0) const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.map, size: 14,
                      color: MalateColors.electricAmber.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    group.region,
                    style: MalateTypography.neonAccent(c.textMuted)
                        .copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.cities.map((city) {
                return GestureDetector(
                  onTap: () => _selectLocation(city.toLocation()),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.asphalt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.sidewalk),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_city,
                            size: 14,
                            color: MalateColors.neonMint.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          city.name,
                          style: MalateTypography.bodySmall
                              .copyWith(color: c.textPrimary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _locationTile(LocationModel place) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: MalateColors.neonMint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: MalateColors.neonMint.withValues(alpha: 0.2)),
        ),
        child: const Icon(Icons.location_on,
            color: MalateColors.neonMint, size: 22),
      ),
      title: Text(
        place.name ?? 'Unknown',
        style: MalateTypography.headlineSmall.copyWith(fontSize: 15),
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

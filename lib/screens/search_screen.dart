import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../models/location_model.dart';
import '../services/mapbox_service.dart';

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
      setState(() { _results = []; _searching = false; });
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
              style: MalateTypography.bodyLarge
                  .copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search places...',
                prefixIcon: const Icon(Icons.location_on,
                    color: MalateColors.neonMint),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: c.textMuted, size: 18),
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
            child: _results.isEmpty && !_searching
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: c.sidewalk),
                    itemBuilder: (_, i) => _tile(_results[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    final c = MalateColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore, size: 56, color: c.textDisabled),
          const SizedBox(height: 16),
          Text('Saan ka pupunta?',
              style: MalateTypography.headlineSmall
                  .copyWith(color: c.textMuted)),
          const SizedBox(height: 8),
          Text('Search addresses, landmarks, and places',
              style: MalateTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _tile(LocationModel place) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: MalateColors.neonMint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: MalateColors.neonMint.withValues(alpha: 0.2)),
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
      onTap: () => Navigator.pop(context, {'location': place}),
    );
  }
}

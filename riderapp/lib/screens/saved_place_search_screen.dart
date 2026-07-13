import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../models/saved_place_type.dart';
import '../services/google_maps_places_service.dart';
import '../theme/app_theme.dart';
import 'saved_place_map_confirm_screen.dart';

class SavedPlaceSearchScreen extends StatefulWidget {
  const SavedPlaceSearchScreen({super.key, required this.placeType});

  final SavedPlaceType placeType;

  @override
  State<SavedPlaceSearchScreen> createState() => _SavedPlaceSearchScreenState();
}

class _SavedPlaceSearchScreenState extends State<SavedPlaceSearchScreen> {
  static const Color _bg = Color(0xFF101010);
  static const Color _surface = Color(0xFF151515);
  static const Color _field = Color(0xFF242424);
  static const Color _muted = Color(0xFF9B9B9B);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final GoogleMapsPlacesService _placesService = GoogleMapsPlacesService();

  Timer? _debounce;
  bool _loadingSuggestions = false;
  int _latestRequestId = 0;
  List<Map<String, String>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _cancelPendingSuggestionWork();
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text.trim();
    _cancelPendingSuggestionWork();

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingSuggestions = false;
        _suggestions = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 280), () {
      _fetchSuggestions(query);
    });
  }

  void _cancelPendingSuggestionWork() {
    _debounce?.cancel();
    _debounce = null;
    _latestRequestId++;
  }

  void _setSearchValue(String value) {
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    final requestId = _latestRequestId;
    if (!mounted) return;
    setState(() => _loadingSuggestions = true);

    final results = await _placesService.autocompletePlaces(query);

    if (!mounted || requestId != _latestRequestId) return;
    if (!_searchFocus.hasFocus) return;
    setState(() {
      _loadingSuggestions = false;
      _suggestions = results;
    });
  }

  Future<void> _selectSuggestion(Map<String, String> suggestion) async {
    final selectedAddress = (suggestion['value'] ?? suggestion['name'] ?? '')
        .trim();
    if (selectedAddress.isEmpty) return;

    _cancelPendingSuggestionWork();
    _searchFocus.unfocus();
    _setSearchValue(selectedAddress);
    if (mounted) {
      setState(() {
        _loadingSuggestions = false;
        _suggestions = [];
      });
    }

    gmaps.LatLng target = const gmaps.LatLng(6.5244, 3.3792);
    try {
      final matches = await geocoding.locationFromAddress(selectedAddress);
      if (matches.isNotEmpty) {
        final first = matches.first;
        target = gmaps.LatLng(first.latitude, first.longitude);
      }
    } catch (_) {}

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedPlaceMapConfirmScreen(
          placeType: widget.placeType,
          selectedAddress: selectedAddress,
          initialTarget: target,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: widget.placeType.title,
              onBack: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: _searchField(),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildSuggestions()),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(13, 0, 7, 0),
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E6E6), width: 1.4),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _muted, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              cursorColor: CitiRideTheme.primaryYellow,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search location',
                hintStyle: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFFE6E6E6),
                  size: 22,
                ),
                Image.asset(
                  'images/location_pin.png',
                  width: 19,
                  height: 19,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_loadingSuggestions) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: CitiRideTheme.primaryYellow,
          ),
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Text(
          'Search for a place',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Center(
        child: Text(
          'No matching places found',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 330),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2D2D2D)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return _SuggestionTile(
                      suggestion: suggestion,
                      onTap: () => _selectSuggestion(suggestion),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final Map<String, String> suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (suggestion['name'] ?? '').trim();
    final subtitle = (suggestion['subtitle'] ?? '').trim();
    final distance = (suggestion['distance'] ?? '').trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFE9E9E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF595959),
                size: 16,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9A9A9A),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (distance.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                distance,
                style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 58),
        ],
      ),
    );
  }
}

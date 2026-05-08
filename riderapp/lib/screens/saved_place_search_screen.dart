import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../models/saved_place_type.dart';
import '../services/google_maps_places_service.dart';
import '../theme/app_theme.dart';
import 'saved_place_map_confirm_screen.dart';

class SavedPlaceSearchScreen extends StatefulWidget {
  const SavedPlaceSearchScreen({
    super.key,
    required this.placeType,
  });

  final SavedPlaceType placeType;

  @override
  State<SavedPlaceSearchScreen> createState() => _SavedPlaceSearchScreenState();
}

class _SavedPlaceSearchScreenState extends State<SavedPlaceSearchScreen> {
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

    final results = await _placesService.autocompletePlaces(
      query,
    );

    if (!mounted || requestId != _latestRequestId) return;
    if (!_searchFocus.hasFocus) return;
    setState(() {
      _loadingSuggestions = false;
      _suggestions = results;
    });
  }

  Future<void> _selectSuggestion(Map<String, String> suggestion) async {
    final selectedAddress =
        (suggestion['value'] ?? suggestion['name'] ?? '').trim();
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
      backgroundColor: Theme.of(context).extension<CitiRideThemeColors>()?.surface ?? const Color(0xFFF2F2F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 24,
            color: Color(0xFF2D2F3A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.placeType.title,
          style: const TextStyle(
            color: Color(0xFF2D2F3A),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).extension<CitiRideThemeColors>()?.surface ?? const Color(0xFFF2F2F4),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF666A73),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Search for a place',
                        hintStyle: TextStyle(
                          color: Color(0xFF9D9FA5),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF2E313B),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8E8EB),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFD21DDB),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loadingSuggestions
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF2F323D),
                        ),
                      ),
                    )
                  : _buildSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Text(
          'Search for a place',
          style: TextStyle(
            color: Color(0xFF7A7F88),
            fontSize: 14,
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Center(
        child: Text(
          'No matching places found',
          style: TextStyle(
            color: Color(0xFF7A7F88),
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0xFFD7D9DF)),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return InkWell(
          onTap: () => _selectSuggestion(suggestion),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 18,
                  color: Color(0xFF5C6068),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion['name'] ?? '',
                        style: const TextStyle(
                          color: Color(0xFF2E313B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((suggestion['subtitle'] ?? '').trim().isNotEmpty)
                        Text(
                          suggestion['subtitle'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7F848D),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

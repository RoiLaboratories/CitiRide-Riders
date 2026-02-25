import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../services/google_maps_places_service.dart';
import '../utils/location_manager.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destinationFocus = FocusNode();

  String _currentLocationText = 'Lagos Street';
  bool _loadingLocation = true;
  bool _loadingRecents = true;
  bool _showBookRideButton = false;
  bool _isBooking = false;
  bool _loadingSuggestions = false;
  List<Map<String, dynamic>> _recentLocations = [];
  List<Map<String, String>> _destinationSuggestions = [];
  bool _appliedRouteArgs = false;
  Timer? _suggestionDebounce;
  int _latestSuggestionRequestId = 0;
  final GoogleMapsPlacesService _placesService = GoogleMapsPlacesService();

  static const List<Map<String, dynamic>> _savedLocations = [
    {
      'name': 'Benin City',
      'subtitle': 'Nigeria',
      'distance': '12.6km',
      'icon': Icons.access_time_filled,
    },
    {
      'name': 'Afemai Transport Company',
      'subtitle': 'Dawson Road, Benin City',
      'distance': '<1km',
      'icon': Icons.location_on,
    },
    {
      'name': 'Ring Road Bus Terminal',
      'subtitle': 'Oba Market Road, Benin City 300102',
      'distance': '7.2km',
      'icon': Icons.directions_bus_filled,
    },
  ];

  @override
  void initState() {
    super.initState();
    _destinationController.addListener(_onDestinationChanged);
    _destinationFocus.addListener(_onDestinationFocusChanged);
    _getCurrentLocation();
    _loadRecentLocations();
    LocationManager().addListener(_onLocationsUpdated);
  }

  @override
  void dispose() {
    LocationManager().removeListener(_onLocationsUpdated);
    _suggestionDebounce?.cancel();
    _destinationController.removeListener(_onDestinationChanged);
    _destinationFocus.removeListener(_onDestinationFocusChanged);
    _destinationController.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedRouteArgs) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final prefilledDestination =
        (args?['prefilledDestination'] as String?)?.trim() ?? '';

    if (prefilledDestination.isNotEmpty) {
      _destinationController.text = prefilledDestination;
      _destinationController.selection = TextSelection.fromPosition(
        TextPosition(offset: _destinationController.text.length),
      );
    }

    _appliedRouteArgs = true;
  }

  void _onDestinationFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onDestinationChanged() {
    final query = _destinationController.text.trim();
    if (!mounted) return;

    setState(() => _showBookRideButton = query.isNotEmpty);

    _suggestionDebounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _loadingSuggestions = false;
        _destinationSuggestions = [];
      });
      return;
    }

    _suggestionDebounce = Timer(const Duration(milliseconds: 280), () {
      _fetchDestinationSuggestions(query);
    });
  }

  void _applySuggestion(Map<String, String> suggestion) {
    final destination = (suggestion['value'] ?? '').trim();
    if (destination.isEmpty) return;

    _destinationController.text = destination;
    _destinationController.selection = TextSelection.fromPosition(
      TextPosition(offset: _destinationController.text.length),
    );
    _destinationFocus.unfocus();
  }

  Future<void> _fetchDestinationSuggestions(String query) async {
    final requestId = ++_latestSuggestionRequestId;

    if (!mounted) return;
    setState(() => _loadingSuggestions = true);

    final suggestions = await _placesService.autocompletePlaces(query);
    if (!mounted || requestId != _latestSuggestionRequestId) return;

    setState(() {
      _destinationSuggestions = suggestions;
      _loadingSuggestions = false;
    });
  }

  void _onLocationsUpdated() {
    if (!mounted) return;
    _loadRecentLocations();
  }

  Future<void> _getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        setState(() {
          _currentLocationText = 'Permission required';
          _loadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      String bestText = '';

      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          bestText = [
            place.street,
            place.subLocality,
            place.locality,
          ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
        }
      } catch (_) {}

      if (bestText.isEmpty) {
        final fallbackAddress = await _placesService.reverseGeocodeAddress(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        if (fallbackAddress != null && fallbackAddress.trim().isNotEmpty) {
          bestText = fallbackAddress.trim();
        }
      }

      if (!mounted) return;
      setState(() {
        _currentLocationText =
            bestText.isEmpty ? 'Current location' : bestText;
        _loadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _loadRecentLocations() async {
    setState(() => _loadingRecents = true);
    try {
      final loaded = await LocationManager().getRecentLocations();
      if (!mounted) return;
      setState(() {
        _recentLocations = loaded;
        _loadingRecents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recentLocations = [];
        _loadingRecents = false;
      });
    }
  }

  Future<void> _openBookRide(
    String destination, {
    bool clearDestinationOnReturn = false,
  }) async {
    final cleaned = destination.trim();
    if (cleaned.isEmpty) return;

    await LocationManager().addRecentLocation('Destination', cleaned);
    if (!mounted) return;

    await Navigator.pushNamed(
      context,
      '/bookride',
      arguments: {
        'destination': cleaned,
        'currentLocation': _currentLocationText,
        'pickupTime': DateTime.now().add(const Duration(minutes: 5)),
      },
    );

    if (!mounted || !clearDestinationOnReturn) return;
    _destinationController.clear();
    _destinationFocus.unfocus();
  }

  Future<void> _bookRideFromButton() async {
    if (_isBooking) return;
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) return;

    setState(() => _isBooking = true);
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await _openBookRide(destination, clearDestinationOnReturn: true);
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showingSuggestions =
        _destinationFocus.hasFocus &&
        _destinationController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            size: 30,
            color: Color(0xFF2D2F3A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Route',
          style: TextStyle(
            color: Color(0xFF2D2F3A),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pickupRow(),
            const SizedBox(height: 8),
            _destinationRow(),
            const SizedBox(height: 12),
            Expanded(
              child: showingSuggestions
                  ? _destinationSuggestionsCard()
                  : _savedAndRecentLocationsContent(),
            ),
            if (_showBookRideButton)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _bookRideFromButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1690F0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1690F0),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: _isBooking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Book Ride',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pickupRow() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4D4D6),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1690F0), width: 3),
            ),
            child: const Center(
              child: CircleAvatar(
                radius: 6,
                backgroundColor: Color(0xFF1690F0),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadingLocation ? 'Detecting location...' : _currentLocationText,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2E313B),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.add_rounded, size: 34, color: Color(0xFF2E313B)),
        ],
      ),
    );
  }

  Widget _destinationRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F4),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF1690F0), width: 1.8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF666A73),
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _destinationController,
                    focusNode: _destinationFocus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _bookRideFromButton(),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Your Destination',
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
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8E8EB),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _bookRideFromButton,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFD21DDB),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.swap_vert_rounded, size: 30, color: Color(0xFF2E313B)),
      ],
    );
  }

  Widget _destinationSuggestionsCard() {
    if (_loadingSuggestions) {
      return const Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 12),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFF1690F0),
            ),
          ),
        ),
      );
    }

    if (_destinationSuggestions.isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E9EC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD7D9DF)),
          ),
          child: const Text(
            'No matching places from Google Maps',
            style: TextStyle(
              color: Color(0xFF7A7F88),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E9EC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD7D9DF)),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _destinationSuggestions.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFD7D9DF)),
            itemBuilder: (context, index) {
              final suggestion = _destinationSuggestions[index];
              return InkWell(
                onTap: () => _applySuggestion(suggestion),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                            if ((suggestion['subtitle'] ?? '').isNotEmpty)
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
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.north_west_rounded,
                        size: 16,
                        color: Color(0xFF8B909A),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _locationRow({
    required String title,
    required String subtitle,
    required String distance,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EAEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF4A4D55), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF2E313B),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8C9097),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                distance,
                style: const TextStyle(
                  color: Color(0xFF8C9097),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _savedAndRecentLocationsContent() {
    if (_loadingRecents) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Color(0xFF1690F0),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const Text(
          'Saved Locations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E313B),
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 10),
        ..._savedLocations.map(
          (location) => _locationRow(
            title: location['name'] as String,
            subtitle: location['subtitle'] as String,
            distance: location['distance'] as String,
            icon: location['icon'] as IconData,
            onTap: () => _openBookRide(location['name'] as String),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Recent locations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E313B),
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 10),
        ...(_recentLocations.isEmpty
            ? [
                _locationRow(
                  title: 'No recent locations',
                  subtitle: 'Your searched destinations will appear here',
                  distance: '',
                  icon: Icons.history_rounded,
                  onTap: () {},
                ),
              ]
            : _recentLocations.map((location) {
                final address = (location['address'] as String?) ?? '';
                final name = (location['name'] as String?) ?? 'Destination';
                return _locationRow(
                  title: name,
                  subtitle: address,
                  distance: '<1km',
                  icon: Icons.location_on,
                  onTap: () => _openBookRide(
                    address.isEmpty ? name : address,
                  ),
                );
              }).toList()),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/google_maps_places_service.dart';
import '../utils/location_manager.dart';

enum _RouteInputField { none, pickup, destination }

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();

  bool _loadingPickup = true;
  bool _loadingRecents = true;
  bool _loadingSuggestions = false;
  bool _showBookRideButton = false;
  bool _isBooking = false;
  bool _appliedRouteArgs = false;
  bool _isApplyingSuggestion = false;
  _RouteInputField _activeField = _RouteInputField.none;
  _RouteInputField _suggestionsForField = _RouteInputField.none;

  List<Map<String, dynamic>> _savedLocations = [];
  List<Map<String, dynamic>> _recentLocations = [];
  List<Map<String, String>> _suggestions = [];
  gmaps.LatLng? _pickupCoordinates;
  gmaps.LatLng? _destinationCoordinates;

  Timer? _suggestionDebounce;
  int _latestSuggestionRequestId = 0;
  final GoogleMapsPlacesService _placesService = GoogleMapsPlacesService();

  @override
  void initState() {
    super.initState();
    _pickupController.addListener(_onPickupChanged);
    _destinationController.addListener(_onDestinationChanged);
    _pickupFocus.addListener(_onPickupFocusChanged);
    _destinationFocus.addListener(_onDestinationFocusChanged);

    _getCurrentLocation();
    _loadSavedLocations();
    _loadRecentLocations();
    LocationManager().addListener(_onLocationsUpdated);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedRouteArgs) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final prefilledDestination =
        (args?['prefilledDestination'] as String?)?.trim() ?? '';
    final prefilledPickup = (args?['prefilledPickup'] as String?)?.trim() ?? '';

    if (prefilledPickup.isNotEmpty) {
      _pickupController.text = prefilledPickup;
      _pickupController.selection = TextSelection.fromPosition(
        TextPosition(offset: _pickupController.text.length),
      );
    }

    if (prefilledDestination.isNotEmpty) {
      _destinationController.text = prefilledDestination;
      _destinationController.selection = TextSelection.fromPosition(
        TextPosition(offset: _destinationController.text.length),
      );
      _showBookRideButton = true;
    }

    _appliedRouteArgs = true;
  }

  @override
  void dispose() {
    LocationManager().removeListener(_onLocationsUpdated);
    _cancelPendingSuggestionWork();

    _pickupController.removeListener(_onPickupChanged);
    _destinationController.removeListener(_onDestinationChanged);
    _pickupFocus.removeListener(_onPickupFocusChanged);
    _destinationFocus.removeListener(_onDestinationFocusChanged);

    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocus.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  void _onPickupFocusChanged() {
    if (!mounted) return;
    if (!_pickupFocus.hasFocus && !_destinationFocus.hasFocus) {
      _cancelPendingSuggestionWork();
    }
    setState(() {
      if (_pickupFocus.hasFocus) {
        _activeField = _RouteInputField.pickup;
      } else if (!_destinationFocus.hasFocus) {
        _activeField = _RouteInputField.none;
        _loadingSuggestions = false;
        _suggestionsForField = _RouteInputField.none;
        _suggestions = [];
      }
    });
  }

  void _onDestinationFocusChanged() {
    if (!mounted) return;
    if (!_destinationFocus.hasFocus && !_pickupFocus.hasFocus) {
      _cancelPendingSuggestionWork();
    }
    setState(() {
      if (_destinationFocus.hasFocus) {
        _activeField = _RouteInputField.destination;
      } else if (!_pickupFocus.hasFocus) {
        _activeField = _RouteInputField.none;
        _loadingSuggestions = false;
        _suggestionsForField = _RouteInputField.none;
        _suggestions = [];
      }
    });
  }

  void _onPickupChanged() {
    if (_isApplyingSuggestion) return;
    final query = _pickupController.text.trim();
    _pickupCoordinates = null;
    _requestSuggestions(query, field: _RouteInputField.pickup);
  }

  void _onDestinationChanged() {
    if (_isApplyingSuggestion) return;
    final query = _destinationController.text.trim();
    _destinationCoordinates = null;
    if (!mounted) return;
    setState(() => _showBookRideButton = query.isNotEmpty);
    _requestSuggestions(query, field: _RouteInputField.destination);
  }

  void _requestSuggestions(
    String query, {
    required _RouteInputField field,
  }) {
    _cancelPendingSuggestionWork();

    final shouldFetch = (field == _RouteInputField.pickup && _pickupFocus.hasFocus) ||
        (field == _RouteInputField.destination && _destinationFocus.hasFocus);

    if (!shouldFetch) return;

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingSuggestions = false;
        _suggestions = [];
        _suggestionsForField = _RouteInputField.none;
      });
      return;
    }

    _suggestionDebounce = Timer(const Duration(milliseconds: 280), () {
      _fetchSuggestions(query, field: field);
    });
  }

  void _cancelPendingSuggestionWork() {
    _suggestionDebounce?.cancel();
    _suggestionDebounce = null;
    _latestSuggestionRequestId++;
  }

  void _setControllerValue(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _fetchSuggestions(
    String query, {
    required _RouteInputField field,
  }) async {
    final requestId = _latestSuggestionRequestId;
    if (!mounted) return;
    setState(() {
      _activeField = field;
      _loadingSuggestions = true;
      _suggestionsForField = field;
    });

    final suggestions = await _placesService.autocompletePlaces(
      query,
    );
    if (!mounted || requestId != _latestSuggestionRequestId) return;

    final fieldStillFocused =
        (field == _RouteInputField.pickup && _pickupFocus.hasFocus) ||
        (field == _RouteInputField.destination && _destinationFocus.hasFocus);
    if (!fieldStillFocused) return;

    setState(() {
      _suggestions = suggestions;
      _loadingSuggestions = false;
      _suggestionsForField = field;
    });
  }

  Future<void> _applySuggestion(
    Map<String, String> suggestion, {
    required _RouteInputField targetField,
  }) async {
    final value =
        (suggestion['value'] ?? suggestion['name'] ?? suggestion['subtitle'] ?? '')
            .trim();
    if (value.isEmpty) return;

    final applyToPickup = targetField == _RouteInputField.pickup;
    _cancelPendingSuggestionWork();
    _isApplyingSuggestion = true;

    if (applyToPickup) {
      _setControllerValue(_pickupController, value);
    } else {
      _setControllerValue(_destinationController, value);
    }

    _isApplyingSuggestion = false;

    setState(() {
      _activeField = _RouteInputField.none;
      _loadingSuggestions = false;
      _suggestionsForField = _RouteInputField.none;
      _showBookRideButton = _destinationController.text.trim().isNotEmpty;
      _suggestions = [];
    });

    if (applyToPickup) {
      _pickupFocus.unfocus();
    } else {
      _destinationFocus.unfocus();
    }

    final coordinates = await _resolveSuggestionLatLng(suggestion, fallbackValue: value);
    if (!mounted) return;

    final latestValue = applyToPickup
        ? _pickupController.text.trim()
        : _destinationController.text.trim();
    if (latestValue != value) return;

    if (coordinates != null) {
      setState(() {
        if (applyToPickup) {
          _pickupCoordinates = coordinates;
        } else {
          _destinationCoordinates = coordinates;
        }
      });
    }
  }

  Future<gmaps.LatLng?> _resolveSuggestionLatLng(
    Map<String, String> suggestion, {
    required String fallbackValue,
  }) async {
    final placeId = (suggestion['placeId'] ?? '').trim();
    if (placeId.isNotEmpty) {
      final coordinates = await _placesService.getPlaceCoordinates(placeId);
      if (coordinates != null) {
        final lat = coordinates['lat'];
        final lng = coordinates['lng'];
        if (lat != null && lng != null) {
          return gmaps.LatLng(lat, lng);
        }
      }
    }

    return _resolveAddressToLatLng(fallbackValue);
  }

  Future<gmaps.LatLng?> _resolveAddressToLatLng(String address) async {
    final cleanedAddress = address.trim();
    if (cleanedAddress.isEmpty) return null;

    try {
      final matches = await geocoding.locationFromAddress(cleanedAddress);
      if (matches.isEmpty) return null;

      final first = matches.first;
      return gmaps.LatLng(first.latitude, first.longitude);
    } catch (_) {
      return null;
    }
  }

  void _swapLocations() {
    final pickup = _pickupController.text.trim();
    final destination = _destinationController.text.trim();
    final pickupCoordinates = _pickupCoordinates;
    final destinationCoordinates = _destinationCoordinates;

    _pickupController.text = destination;
    _destinationController.text = pickup;
    _pickupCoordinates = destinationCoordinates;
    _destinationCoordinates = pickupCoordinates;
    _pickupController.selection = TextSelection.fromPosition(
      TextPosition(offset: _pickupController.text.length),
    );
    _destinationController.selection = TextSelection.fromPosition(
      TextPosition(offset: _destinationController.text.length),
    );

    setState(() {
      _showBookRideButton = _destinationController.text.trim().isNotEmpty;
    });
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final homeAddress = (prefs.getString('saved_place_home_address') ?? '').trim();
    final officeAddress =
        (prefs.getString('saved_place_office_address') ?? '').trim();

    final loaded = <Map<String, dynamic>>[];
    if (homeAddress.isNotEmpty) {
      loaded.add({
        'name': 'Home',
        'subtitle': homeAddress,
        'distance': '',
        'icon': Icons.home_rounded,
      });
    }
    if (officeAddress.isNotEmpty) {
      loaded.add({
        'name': 'Office',
        'subtitle': officeAddress,
        'distance': '',
        'icon': Icons.work_rounded,
      });
    }

    if (!mounted) return;
    setState(() {
      _savedLocations = loaded;
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
        if (!mounted) return;
        setState(() => _loadingPickup = false);
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
      if (_pickupController.text.trim().isEmpty) {
        _pickupController.text = bestText.isEmpty ? 'Current location' : bestText;
      }
      setState(() {
        _pickupCoordinates = gmaps.LatLng(position.latitude, position.longitude);
        _loadingPickup = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPickup = false);
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
    gmaps.LatLng? pickupCoordinates,
    gmaps.LatLng? destinationCoordinates,
  }) async {
    final cleaned = destination.trim();
    if (cleaned.isEmpty) return;

    await LocationManager().addRecentLocation('Destination', cleaned);
    if (!mounted) return;

    final pickup = _pickupController.text.trim();
    final args = <String, dynamic>{
      'destination': cleaned,
      'currentLocation': pickup.isEmpty ? 'Current location' : pickup,
      'pickupTime': DateTime.now().add(const Duration(minutes: 5)),
      if (pickupCoordinates != null) 'pickupLat': pickupCoordinates.latitude,
      if (pickupCoordinates != null) 'pickupLng': pickupCoordinates.longitude,
      if (destinationCoordinates != null)
        'destinationLat': destinationCoordinates.latitude,
      if (destinationCoordinates != null)
        'destinationLng': destinationCoordinates.longitude,
    };

    await Navigator.pushNamed(
      context,
      '/bookride',
      arguments: args,
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
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final pickupLabel = _pickupController.text.trim();
      final resolvedPickupCoordinates =
          _pickupCoordinates ?? await _resolveAddressToLatLng(pickupLabel);
      final resolvedDestinationCoordinates =
          _destinationCoordinates ?? await _resolveAddressToLatLng(destination);

      await _openBookRide(
        destination,
        clearDestinationOnReturn: true,
        pickupCoordinates: resolvedPickupCoordinates,
        destinationCoordinates: resolvedDestinationCoordinates,
      );
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  void _selectLocationFromList(String address) {
    if (_activeField == _RouteInputField.pickup) {
      _pickupController.text = address;
      _pickupFocus.unfocus();
      _resolveAddressToLatLng(address).then((coordinates) {
        if (!mounted || coordinates == null) return;
        setState(() => _pickupCoordinates = coordinates);
      });
      return;
    }

    _destinationController.text = address;
    _destinationFocus.unfocus();
    _resolveAddressToLatLng(address).then((coordinates) {
      if (!mounted || coordinates == null) return;
      setState(() => _destinationCoordinates = coordinates);
    });
    _bookRideFromButton();
  }

  @override
  Widget build(BuildContext context) {
    final editingPickup = _activeField == _RouteInputField.pickup;
    final editingDestination = _activeField == _RouteInputField.destination;
    final showingSuggestions = (editingPickup &&
            _pickupController.text.trim().isNotEmpty) ||
        (editingDestination && _destinationController.text.trim().isNotEmpty);

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
                  ? _suggestionsCard()
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
    return InkWell(
      onTap: () {
        setState(() => _activeField = _RouteInputField.pickup);
        _pickupFocus.requestFocus();
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
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
              child: TextField(
                controller: _pickupController,
                focusNode: _pickupFocus,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: _loadingPickup ? 'Detecting location...' : 'Pickup',
                  hintStyle: const TextStyle(
                    color: Color(0xFF7F838A),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2E313B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() => _activeField = _RouteInputField.pickup);
                _pickupFocus.requestFocus();
              },
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.add_rounded,
                  size: 34,
                  color: Color(0xFF2E313B),
                ),
              ),
            ),
          ],
        ),
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
                    onTap: () {
                      setState(() => _activeField = _RouteInputField.destination);
                      _destinationFocus.requestFocus();
                    },
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
        InkWell(
          onTap: _swapLocations,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(
              Icons.swap_vert_rounded,
              size: 30,
              color: Color(0xFF2E313B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _suggestionsCard() {
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

    if (_suggestions.isEmpty) {
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
            'No matching places found. Try another search term.',
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
            itemCount: _suggestions.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFD7D9DF)),
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              final targetField = _suggestionsForField == _RouteInputField.none
                  ? (_activeField == _RouteInputField.none
                        ? _RouteInputField.destination
                        : _activeField)
                  : _suggestionsForField;
              return InkWell(
                onTap: () => _applySuggestion(
                  suggestion,
                  targetField: targetField,
                ),
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
        if (_savedLocations.isNotEmpty) ...[
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
              onTap: () => _selectLocationFromList(
                location['subtitle'] as String,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
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
                  onTap: () => _selectLocationFromList(
                    address.isEmpty ? name : address,
                  ),
                );
              }).toList()),
      ],
    );
  }
}

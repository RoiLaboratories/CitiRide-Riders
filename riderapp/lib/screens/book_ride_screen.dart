import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as osm;

import '../components/chat_sheet.dart';
import '../components/driver_found_sheet.dart';
import '../components/pickup_collapsed_sheet.dart';
import '../components/ride_modal.dart';
import '../components/ride_top_bar.dart';
import '../ride_flow/ride_history_store.dart';
import 'home_screen.dart';
import '../utils/google_map_style.dart';

enum RideFlowState {
  enterRide,
  pickupCollapsed,
  driverFound,
  chat,
}

class BookRideScreen extends StatefulWidget {
  final String? selectedDestination;

  const BookRideScreen({
    super.key,
    this.selectedDestination,
  });

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  RideFlowState _flowState = RideFlowState.enterRide;

  gmaps.LatLng _fromLatLng = const gmaps.LatLng(6.5244, 3.3792);
  gmaps.LatLng _toLatLng = const gmaps.LatLng(6.4654, 3.4064);
  List<gmaps.LatLng> _routePoints = const [];
  gmaps.GoogleMapController? _googleMapController;
  gmaps.BitmapDescriptor _pickupMarkerIcon =
      gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueAzure,
      );
  gmaps.BitmapDescriptor _destinationMarkerIcon =
      gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueViolet,
      );
  gmaps.BitmapDescriptor _carMarkerIcon =
      gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueOrange,
      );

  String _fromLabel = 'Current location';
  String _toLabel = 'Destination';
  bool _didInitializeRoute = false;
  bool _isRefreshingRoute = false;
  bool _hasAddedRideEntry = false;

  @override
  void initState() {
    super.initState();
    _loadMapMarkerIcons();
    _routePoints = _buildBentRoutePoints(_fromLatLng, _toLatLng);
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeRoute) return;
    _didInitializeRoute = true;
    _initializeRouteContext();
  }

  Future<void> _initializeRouteContext() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        const {};

    final destinationFromArgs = (args['destination'] as String?)?.trim() ?? '';
    final currentLocationFromArgs =
        (args['currentLocation'] as String?)?.trim() ?? '';

    final selectedDestination = (widget.selectedDestination ?? '').trim();
    final toLabel = destinationFromArgs.isNotEmpty
        ? destinationFromArgs
        : (selectedDestination.isNotEmpty ? selectedDestination : _toLabel);

    final fromLabel = currentLocationFromArgs.isNotEmpty
        ? currentLocationFromArgs
        : _fromLabel;

    final pickupLat = _parseDouble(args['pickupLat']);
    final pickupLng = _parseDouble(args['pickupLng']);
    final destinationLat = _parseDouble(args['destinationLat']);
    final destinationLng = _parseDouble(args['destinationLng']);

    final providedPickup =
        pickupLat != null && pickupLng != null
        ? gmaps.LatLng(pickupLat, pickupLng)
        : null;
    final providedDestination =
        destinationLat != null && destinationLng != null
        ? gmaps.LatLng(destinationLat, destinationLng)
        : null;

    if (!mounted) return;
    setState(() {
      _toLabel = toLabel;
      _fromLabel = fromLabel;
    });

    await _refreshLiveMapData(
      destinationLabel: toLabel,
      currentLabel: fromLabel,
      providedPickup: providedPickup,
      providedDestination: providedDestination,
    );
  }

  Future<void> _loadMapMarkerIcons() async {
    if (kIsWeb) return;

    try {
      final pickupMarker = await gmaps.BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(52, 52)),
        'images/location_pointer.png',
        width: 52,
        height: 52,
      );
      final destinationMarker = await gmaps.BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(46, 46)),
        'images/destination_pointer.png',
        width: 46,
        height: 46,
      );
      final carMarker = await gmaps.BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(46, 22)),
        'images/car.png',
        width: 46,
        height: 22,
      );

      if (!mounted) return;
      setState(() {
        _pickupMarkerIcon = pickupMarker;
        _destinationMarkerIcon = destinationMarker;
        _carMarkerIcon = carMarker;
      });
    } catch (_) {}
  }

  bool _looksLikeCoordinates(String value) {
    final pattern = RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$');
    return pattern.hasMatch(value);
  }

  double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<String?> _resolveReadableLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final fullAddress = [
        place.street,
        place.subLocality,
        place.locality,
      ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

      if (fullAddress.isNotEmpty) return fullAddress;

      final fallback = [
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

      return fallback.isEmpty ? null : fallback;
    } catch (_) {
      return null;
    }
  }

  Future<gmaps.LatLng?> _resolveAddressToLatLng(String locationLabel) async {
    final label = locationLabel.trim();
    if (label.isEmpty) return null;

    try {
      final matches = await geocoding.locationFromAddress(label);
      if (matches.isNotEmpty) {
        final first = matches.first;
        return gmaps.LatLng(first.latitude, first.longitude);
      }
    } catch (_) {}

    return null;
  }

  Future<gmaps.LatLng> _resolveDestinationLatLng(
    String destinationLabel,
    gmaps.LatLng from,
  ) async {
    if (destinationLabel.trim().isEmpty) {
      return gmaps.LatLng(from.latitude + 0.012, from.longitude + 0.015);
    }

    final resolved = await _resolveAddressToLatLng(destinationLabel);
    if (resolved != null) return resolved;

    return gmaps.LatLng(from.latitude + 0.012, from.longitude + 0.015);
  }

  List<gmaps.LatLng> _buildBentRoutePoints(
    gmaps.LatLng from,
    gmaps.LatLng to, {
    int segments = 48,
    double bendFactor = 0.22,
  }) {
    final deltaLat = to.latitude - from.latitude;
    final deltaLng = to.longitude - from.longitude;
    final distance = math.sqrt(
      (deltaLat * deltaLat) + (deltaLng * deltaLng),
    );

    var perpLat = -deltaLng;
    var perpLng = deltaLat;
    final perpLength = math.sqrt((perpLat * perpLat) + (perpLng * perpLng));
    if (perpLength != 0) {
      perpLat /= perpLength;
      perpLng /= perpLength;
    }

    final control = gmaps.LatLng(
      ((from.latitude + to.latitude) / 2) + (perpLat * distance * bendFactor),
      ((from.longitude + to.longitude) / 2) + (perpLng * distance * bendFactor),
    );

    final points = <gmaps.LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final oneMinusT = 1 - t;
      points.add(
        gmaps.LatLng(
          (oneMinusT * oneMinusT * from.latitude) +
              (2 * oneMinusT * t * control.latitude) +
              (t * t * to.latitude),
          (oneMinusT * oneMinusT * from.longitude) +
              (2 * oneMinusT * t * control.longitude) +
              (t * t * to.longitude),
        ),
      );
    }
    return points;
  }

  Future<void> _refreshLiveMapData({
    required String destinationLabel,
    required String currentLabel,
    gmaps.LatLng? providedPickup,
    gmaps.LatLng? providedDestination,
  }) async {
    if (mounted) {
      setState(() => _isRefreshingRoute = true);
    }

    var from = providedPickup ?? _fromLatLng;
    var fromLabel = currentLabel.trim();

    try {
      final wantsManualPickup =
          fromLabel.isNotEmpty &&
          fromLabel.toLowerCase() != 'current location' &&
          !_looksLikeCoordinates(fromLabel);

      if (wantsManualPickup) {
        final resolved = await _resolveAddressToLatLng(fromLabel);
        if (resolved != null) {
          from = resolved;
        }
      } else if (providedPickup == null && await _ensureLocationPermission()) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        from = gmaps.LatLng(position.latitude, position.longitude);

        final resolvedLabel = await _resolveReadableLocation(
          position.latitude,
          position.longitude,
        );
        if (resolvedLabel != null && resolvedLabel.trim().isNotEmpty) {
          fromLabel = resolvedLabel;
        } else if (fromLabel.isEmpty || _looksLikeCoordinates(fromLabel)) {
          fromLabel = 'Current location';
        }
      } else if (fromLabel.isEmpty || _looksLikeCoordinates(fromLabel)) {
        fromLabel = 'Current location';
      }

      final to =
          providedDestination ??
          await _resolveDestinationLatLng(destinationLabel, from);
      final routePoints = _buildBentRoutePoints(from, to);

      if (!mounted) return;
      setState(() {
        _fromLatLng = from;
        _toLatLng = to;
        _routePoints = routePoints;
        _fromLabel = fromLabel.isEmpty ? _fromLabel : fromLabel;
        _toLabel = destinationLabel.isEmpty ? _toLabel : destinationLabel;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _routePoints = _buildBentRoutePoints(_fromLatLng, _toLatLng);
      });
    } finally {
      if (mounted) {
        setState(() => _isRefreshingRoute = false);
      }
    }
  }

  void _editRoute() {
    Navigator.pushReplacementNamed(
      context,
      '/route',
      arguments: {
        'prefilledDestination': _toLabel,
        'prefilledPickup': _fromLabel,
      },
    );
  }

  void _recordRideBooking() {
    if (_hasAddedRideEntry) return;
    _hasAddedRideEntry = true;
    RideHistoryStore.instance.addUpcomingRide(
      pickup: _fromLabel,
      destination: _toLabel,
    );
  }

  void _closeRideFlowToRides() {
    _recordRideBooking();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(initialTabIndex: 1),
      ),
      (route) => false,
    );
  }

  void _recenterOnPickup() {
    if (kIsWeb) return;
    final controller = _googleMapController;
    if (controller == null) return;

    controller.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: _fromLatLng,
          zoom: 15,
        ),
      ),
    );
  }

  int _estimatedEtaMinutes() {
    final meters = Geolocator.distanceBetween(
      _fromLatLng.latitude,
      _fromLatLng.longitude,
      _toLatLng.latitude,
      _toLatLng.longitude,
    );
    final minutes = ((meters / 1000) / 30 * 60).round();
    return minutes.clamp(3, 45);
  }

  Widget _mapMiniPill({
    required String text,
    required Color color,
    required bool rightAligned,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: rightAligned ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _handleSheetNotification(DraggableScrollableNotification notification) {
    if (_flowState == RideFlowState.chat && notification.extent <= 0.28) {
      _closeRideFlowToRides();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final minSize = _flowState == RideFlowState.chat ? 0.22 : 0.35;
    final initialSize = _flowState == RideFlowState.chat ? 0.82 : 0.6;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SafeArea(
        child: Stack(
          children: [
            _buildRideMap(),
            Positioned(
              left: 24,
              top: 132,
              child: _mapMiniPill(
                text: '${_estimatedEtaMinutes()} mins',
                color: const Color(0xFF1690F0),
                rightAligned: false,
              ),
            ),
            Positioned(
              right: 34,
              top: 94,
              child: _mapMiniPill(
                text: '\u20A63,500',
                color: const Color(0xFFD21DDB),
                rightAligned: true,
              ),
            ),
            Positioned(
              right: 18,
              bottom: 228,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _recenterOnPickup,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7F0),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(24),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gps_fixed_rounded,
                      size: 20,
                      color: Color(0xFF3A341F),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 10,
              child: RideTopBar(
                fromLocation: _fromLabel,
                toLocation: _toLabel,
                onRouteTap: _editRoute,
              ),
            ),
            NotificationListener<DraggableScrollableNotification>(
              onNotification: _handleSheetNotification,
              child: DraggableScrollableSheet(
                initialChildSize: initialSize,
                minChildSize: minSize,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                        reverseCurve: Curves.easeInCubic,
                      );

                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(curved),
                          child: child,
                        ),
                      );
                    },
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: _buildSheetContent(scrollController),
                  );
                },
              ),
            ),
            if (_isRefreshingRoute)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withAlpha(18),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Color(0xFF1690F0),
                        ),
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

  Widget _buildSheetContent(ScrollController scrollController) {
    switch (_flowState) {
      case RideFlowState.enterRide:
        return RideModal(
          key: const ValueKey('enterRide'),
          scrollController: scrollController,
          onContinue: () {
            setState(() {
              _flowState = RideFlowState.pickupCollapsed;
            });
          },
        );

      case RideFlowState.pickupCollapsed:
        return PickupCollapsedSheet(
          key: const ValueKey('pickup'),
          pickupLabel: _fromLabel,
          destinationLabel: _toLabel,
          onSearchTap: _editRoute,
          onConfirm: () {
            _recordRideBooking();
            setState(() {
              _flowState = RideFlowState.driverFound;
            });
          },
        );

      case RideFlowState.driverFound:
        return DriverFoundSheet(
          key: const ValueKey('driverFound'),
          scrollController: scrollController,
          onConfirm: () {
            setState(() {
              _flowState = RideFlowState.chat;
            });
          },
        );

      case RideFlowState.chat:
        return ChatSheet(
          key: const ValueKey('chat'),
          scrollController: scrollController,
          onClose: _closeRideFlowToRides,
        );
    }
  }

  Widget _buildRideMap() {
    final points = _routePoints.isEmpty
        ? _buildBentRoutePoints(_fromLatLng, _toLatLng)
        : _routePoints;
    int split = (points.length / 2).round();
    if (split < 2) split = 2;
    if (split >= points.length) split = points.length - 1;
    final carIndex =
        (points.length * 0.26).round().clamp(0, points.length - 1);
    final carLatLng = points[carIndex];

    final firstSegment = points.sublist(0, split);
    final secondSegment = points.sublist(split - 1);

    final mapKey =
        '${_fromLatLng.latitude}_${_fromLatLng.longitude}_${_toLatLng.latitude}_${_toLatLng.longitude}_${points.length}';

    if (kIsWeb) {
      final from = osm.LatLng(_fromLatLng.latitude, _fromLatLng.longitude);
      final webFirst = firstSegment
          .map((point) => osm.LatLng(point.latitude, point.longitude))
          .toList();
      final webSecond = secondSegment
          .map((point) => osm.LatLng(point.latitude, point.longitude))
          .toList();

      return fm.FlutterMap(
        key: ValueKey('ride_map_web_$mapKey'),
        options: fm.MapOptions(
          initialCenter: from,
          initialZoom: 13,
        ),
        children: [
          fm.TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.sureride',
          ),
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                points: webFirst,
                color: Colors.blue,
                strokeWidth: 5,
              ),
              fm.Polyline(
                points: webSecond,
                color: Colors.purple,
                strokeWidth: 5,
              ),
            ],
          ),
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                point: from,
                width: 46,
                height: 46,
                child: Image.asset(
                  'images/location_pointer.png',
                  fit: BoxFit.contain,
                ),
              ),
              fm.Marker(
                point: osm.LatLng(_toLatLng.latitude, _toLatLng.longitude),
                width: 44,
                height: 44,
                child: Image.asset(
                  'images/destination_pointer.png',
                  fit: BoxFit.contain,
                ),
              ),
              fm.Marker(
                point: osm.LatLng(carLatLng.latitude, carLatLng.longitude),
                width: 44,
                height: 22,
                child: Image.asset(
                  'images/car.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return gmaps.GoogleMap(
      key: ValueKey('ride_map_mobile_$mapKey'),
      initialCameraPosition: gmaps.CameraPosition(
        target: _fromLatLng,
        zoom: 13,
      ),
      onMapCreated: (controller) {
        _googleMapController = controller;
      },
      mapType: gmaps.MapType.normal,
      compassEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      myLocationEnabled: true,
      style: kGoogleMapGrayscaleStyle,
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: _fromLatLng,
          icon: _pickupMarkerIcon,
          anchor: const Offset(0.5, 1),
          infoWindow: const gmaps.InfoWindow(
            title: 'Pickup',
            snippet: 'Current location',
          ),
        ),
        gmaps.Marker(
          markerId: const gmaps.MarkerId('destination'),
          position: _toLatLng,
          icon: _destinationMarkerIcon,
          anchor: const Offset(0.5, 1),
          infoWindow: gmaps.InfoWindow(
            title: 'Destination',
            snippet: _toLabel,
          ),
        ),
        gmaps.Marker(
          markerId: const gmaps.MarkerId('car'),
          position: carLatLng,
          icon: _carMarkerIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const gmaps.InfoWindow(
            title: 'Driver',
          ),
        ),
      },
      polylines: {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route_from'),
          points: firstSegment,
          color: Colors.blue,
          width: 5,
        ),
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route_to'),
          points: secondSegment,
          color: Colors.purple,
          width: 5,
        ),
      },
    );
  }
}

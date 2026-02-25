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
  gmaps.LatLng _midPoint = const gmaps.LatLng(6.4949, 3.3928);
  gmaps.BitmapDescriptor _pickupMarkerIcon =
      gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueAzure,
      );

  String _fromLabel = 'Current location';
  String _toLabel = 'Destination';
  bool _didInitializeRoute = false;

  @override
  void initState() {
    super.initState();
    _loadPickupMarkerIcon();
    _midPoint = _calculateMidPoint(_fromLatLng, _toLatLng);
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

    String fromLabel = _fromLabel;
    if (currentLocationFromArgs.isNotEmpty &&
        !_looksLikeCoordinates(currentLocationFromArgs)) {
      fromLabel = currentLocationFromArgs;
    }

    if (!mounted) return;
    setState(() {
      _toLabel = toLabel;
      _fromLabel = fromLabel;
    });

    await _refreshLiveMapData(destinationLabel: toLabel, currentLabel: fromLabel);
  }

  Future<void> _loadPickupMarkerIcon() async {
    if (kIsWeb) return;

    try {
      final marker = await gmaps.BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(52, 52)),
        'images/location_pointer.png',
        width: 52,
        height: 52,
      );

      if (!mounted) return;
      setState(() {
        _pickupMarkerIcon = marker;
      });
    } catch (_) {}
  }

  bool _looksLikeCoordinates(String value) {
    final pattern = RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$');
    return pattern.hasMatch(value);
  }

  gmaps.LatLng _calculateMidPoint(gmaps.LatLng from, gmaps.LatLng to) {
    return gmaps.LatLng(
      (from.latitude + to.latitude) / 2,
      (from.longitude + to.longitude) / 2,
    );
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

      if (fullAddress.isNotEmpty) {
        return fullAddress;
      }

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

  Future<gmaps.LatLng> _resolveDestinationLatLng(
    String destinationLabel,
    gmaps.LatLng from,
  ) async {
    if (destinationLabel.trim().isEmpty) {
      return gmaps.LatLng(from.latitude + 0.012, from.longitude + 0.015);
    }

    try {
      final matches = await geocoding.locationFromAddress(destinationLabel);
      if (matches.isNotEmpty) {
        final first = matches.first;
        return gmaps.LatLng(first.latitude, first.longitude);
      }
    } catch (_) {}

    return gmaps.LatLng(from.latitude + 0.012, from.longitude + 0.015);
  }

  Future<void> _refreshLiveMapData({
    required String destinationLabel,
    required String currentLabel,
  }) async {
    var from = _fromLatLng;
    var fromLabel = currentLabel;

    if (await _ensureLocationPermission()) {
      try {
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
        } else if (fromLabel.trim().isEmpty || _looksLikeCoordinates(fromLabel)) {
          fromLabel = 'Current location';
        }
      } catch (_) {
        if (fromLabel.trim().isEmpty || _looksLikeCoordinates(fromLabel)) {
          fromLabel = 'Current location';
        }
      }
    }

    final to = await _resolveDestinationLatLng(destinationLabel, from);
    final mid = _calculateMidPoint(from, to);

    if (!mounted) return;
    setState(() {
      _fromLatLng = from;
      _toLatLng = to;
      _midPoint = mid;
      _fromLabel = fromLabel;
      _toLabel = destinationLabel.isEmpty ? _toLabel : destinationLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SafeArea(
        child: Stack(
          children: [
            _buildRideMap(),
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: RideTopBar(
                fromLocation: _fromLabel,
                toLocation: _toLabel,
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.35,
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
          scrollController: scrollController,
          onSearchTap: () {},
          onConfirm: () {
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
        );
    }
  }

  Widget _buildRideMap() {
    final mapKey =
        '${_fromLatLng.latitude}_${_fromLatLng.longitude}_${_toLatLng.latitude}_${_toLatLng.longitude}';

    if (kIsWeb) {
      final from = osm.LatLng(_fromLatLng.latitude, _fromLatLng.longitude);
      final to = osm.LatLng(_toLatLng.latitude, _toLatLng.longitude);
      final mid = osm.LatLng(_midPoint.latitude, _midPoint.longitude);

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
                points: [from, mid],
                color: Colors.blue,
                strokeWidth: 5,
              ),
              fm.Polyline(
                points: [mid, to],
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
                point: to,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFD21DDB),
                  size: 34,
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
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueViolet,
          ),
          infoWindow: gmaps.InfoWindow(
            title: 'Destination',
            snippet: _toLabel,
          ),
        ),
      },
      polylines: {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route_a'),
          points: [_fromLatLng, _midPoint],
          color: Colors.blue,
          width: 5,
        ),
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route_b'),
          points: [_midPoint, _toLatLng],
          color: Colors.purple,
          width: 5,
        ),
      },
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as osm;

import '../components/floating_action_sheet.dart';
import '../models/chat_message.dart';
import '../models/ride_choice.dart';
import '../models/wallet_balance.dart';
import '../ride_flow/ride_history_store.dart';
import '../theme/app_theme.dart';
import '../utils/google_map_style.dart';
import 'home_screen.dart';

enum _BookRideStage {
  selectRide,
  pickup,
  pickupSearch,
  driverFound,
  arriving,
  moreOptions,
  chat,
  rideArrived,
  driving,
  paymentSummary,
  review,
  reviewSuccess,
  cancelReasons,
}

class BookRideScreen extends StatefulWidget {
  final String? selectedDestination;

  const BookRideScreen({super.key, this.selectedDestination});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  static const Color _bg = Color(0xFF101010);
  static const Color _surface = Color(0xFF151515);
  static const Color _surfaceAlt = Color(0xFF242424);
  static const Color _line = Color(0xFF3A3A3A);
  static const Color _muted = Color(0xFF8F8F8F);
  static const Color _yellow = CitiRideTheme.primaryYellow;
  static const Color _green = Color(0xFF1FD85B);
  static const Color _danger = Color(0xFFFF3B3B);

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();

  _BookRideStage _stage = _BookRideStage.selectRide;
  int _selectedRide = 0;
  int _selectedPayment = 0;
  int? _selectedCancelReason;
  int _rating = 5;
  bool _showAllPaymentOptions = false;

  gmaps.LatLng _fromLatLng = const gmaps.LatLng(6.3350, 5.6037);
  gmaps.LatLng _toLatLng = const gmaps.LatLng(6.3407, 5.6218);
  List<gmaps.LatLng> _routePoints = const [];
  gmaps.GoogleMapController? _googleMapController;
  gmaps.BitmapDescriptor _pickupMarkerIcon = gmaps
      .BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueYellow);
  gmaps.BitmapDescriptor _destinationMarkerIcon = gmaps
      .BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueYellow);
  Offset? _arrivalPillOffset;
  Offset? _durationPillOffset;
  Offset? _pickupPillOffset;
  Offset? _firstCarOffset;
  Offset? _secondCarOffset;

  String _fromLabel = 'Lagos Street';
  String _toLabel = 'Ring Road Bus Terminal';
  bool _didInitializeRoute = false;
  bool _isRefreshingRoute = false;
  bool _syncingMapOverlay = false;
  bool _hasAddedRideEntry = false;
  bool _cancelledRide = false;
  RideLogEntry? _recordedRideEntry;
  Timer? _arrivalTimer;

  final List<ChatMessage> _messages = [
    const ChatMessage(text: 'Alright, coming soon', isUser: false),
  ];

  static const List<RideChoice> _rideChoices = [
    RideChoice(
      title: 'Regular',
      subtitle: 'Mid-size Cars',
      time: '11 mins',
      seats: '4',
      price: '₦3,500',
      oldPrice: '₦4,500',
      image: 'images/regular.png',
    ),
    RideChoice(
      title: 'VIP',
      subtitle: 'Modern Car Models',
      time: '5 mins',
      seats: '2',
      price: '₦7,500',
      oldPrice: '₦9,500',
      image: 'images/vip.png',
    ),
  ];

  static const List<String> _pickupChoices = [
    'My Location',
    'Benin City',
    'Afemai Transport Company',
    'Ring Road Bus Terminal',
  ];

  static const List<String> _cancelReasons = [
    'Car not moving towards me',
    'Long pickup time',
    'Accidental request',
    'Driver asked to pay off the app',
    'Driver asked to cancel',
    'Driver not at pickup point',
    'Driver asked for personal info',
    'Other',
  ];

  static const List<String> _reviewTags = [
    'Safe driving',
    'Great service',
    'Punctual',
    'Good car quality',
    'Respectful',
  ];

  @override
  void initState() {
    super.initState();
    _loadMapMarkerIcons();
    _routePoints = _buildBentRoutePoints(_fromLatLng, _toLatLng);
  }

  @override
  void dispose() {
    _arrivalTimer?.cancel();
    _googleMapController?.dispose();
    _messageController.dispose();
    _reviewController.dispose();
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
    final existingRide = args['existingRide'] == true;
    final initialStage = _stageFromName(
      (args['initialStage'] as String?) ?? '',
    );

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

    final providedPickup = pickupLat != null && pickupLng != null
        ? gmaps.LatLng(pickupLat, pickupLng)
        : null;
    final providedDestination = destinationLat != null && destinationLng != null
        ? gmaps.LatLng(destinationLat, destinationLng)
        : null;

    if (!mounted) return;
    setState(() {
      _fromLabel = fromLabel;
      _toLabel = toLabel;
      _hasAddedRideEntry = existingRide;
      if (initialStage != null) {
        _stage = initialStage;
      }
    });

    await _refreshLiveMapData(
      destinationLabel: toLabel,
      currentLabel: fromLabel,
      providedPickup: providedPickup,
      providedDestination: providedDestination,
    );
  }

  _BookRideStage? _stageFromName(String value) {
    switch (value) {
      case 'chat':
        return _BookRideStage.chat;
      case 'arriving':
        return _BookRideStage.arriving;
      case 'driverFound':
        return _BookRideStage.driverFound;
      case 'driving':
        return _BookRideStage.driving;
      default:
        return null;
    }
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

      if (!mounted) return;
      setState(() {
        _pickupMarkerIcon = pickupMarker;
        _destinationMarkerIcon = destinationMarker;
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
    final distance = math.sqrt((deltaLat * deltaLat) + (deltaLng * deltaLng));

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
    for (var i = 0; i <= segments; i++) {
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

  void _setStage(_BookRideStage stage) {
    _arrivalTimer?.cancel();
    if (!mounted) return;
    setState(() => _stage = stage);

    if (stage == _BookRideStage.arriving) {
      _arrivalTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted || _stage != _BookRideStage.arriving) return;
        setState(() => _stage = _BookRideStage.rideArrived);
      });
    }
  }

  void _recordRideBooking() {
    if (_hasAddedRideEntry || _cancelledRide) return;
    _hasAddedRideEntry = true;
    _recordedRideEntry = RideHistoryStore.instance.addOngoingRide(
      pickup: _fromLabel,
      destination: _toLabel,
    );
  }

  void _closeRideFlowToRides() {
    _recordRideBooking();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen(initialTabIndex: 1)),
      (route) => false,
    );
  }

  void _submitCancelReason() {
    if (_selectedCancelReason == null) return;
    _cancelledRide = true;
    final recordedRide = _recordedRideEntry;
    if (recordedRide != null) {
      RideHistoryStore.instance.removeRide(recordedRide);
      _recordedRideEntry = null;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
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

  void _recenterOnPickup() {
    if (kIsWeb) return;
    final controller = _googleMapController;
    if (controller == null) return;

    controller.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: _fromLatLng, zoom: 15),
      ),
    );
  }

  void _applyPickupChoice(String label) {
    setState(() {
      _fromLabel = label == 'My Location' ? 'Lagos Street' : label;
    });
    _setStage(_BookRideStage.pickup);
  }

  void _sendMessage(String rawMessage) {
    final message = rawMessage.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
    });
    _messageController.clear();
  }

  void _handleRidePayment() {
    final ridePrice = _selectedRide == 0 ? 3500.0 : 7500.0;
    if (_selectedPayment == 1 && WalletBalance.balance < ridePrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have enough wallet funds.')),
      );
      return;
    }

    if (_selectedPayment == 1) {
      WalletBalance.balance -= ridePrice;
    }

    _setStage(_BookRideStage.pickup);
  }

  Future<void> _showShareRideSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FloatingActionSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _circleIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                  size: 36,
                  dark: true,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Share ride details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Follow this ride in real-time by sharing your ride details with the screenshot',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ridePreviewCard(scale: 0.86),
                  const SizedBox(width: 12),
                  _ridePreviewCard(scale: 0.72),
                ],
              ),
              const SizedBox(height: 26),
              _primaryButton('Share ride', () => Navigator.pop(context)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCancelRideConfirmation() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FloatingActionSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _circleIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                  size: 36,
                  dark: true,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Are you sure?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Do you want to cancel the ride? You will be charged a fee to compensate for the driver\'s time',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 26),
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Cancellation fee',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    r'$350',
                    style: TextStyle(
                      color: _danger,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _dangerButton('Cancel ride', () {
                Navigator.pop(context);
                _setStage(_BookRideStage.cancelReasons);
              }),
              const SizedBox(height: 10),
              _primaryButton('Wait for driver', () => Navigator.pop(context)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _BookRideStage.paymentSummary:
        return _buildPaymentSummaryScreen();
      case _BookRideStage.review:
        return _buildReviewScreen();
      case _BookRideStage.reviewSuccess:
        return _buildReviewSuccessScreen();
      case _BookRideStage.cancelReasons:
        return _buildCancelReasonScreen();
      case _BookRideStage.selectRide:
      case _BookRideStage.pickup:
      case _BookRideStage.pickupSearch:
      case _BookRideStage.driverFound:
      case _BookRideStage.arriving:
      case _BookRideStage.moreOptions:
      case _BookRideStage.chat:
      case _BookRideStage.rideArrived:
      case _BookRideStage.driving:
        return _buildMapFlowScreen();
    }
  }

  Widget _buildMapFlowScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildRideMap()),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(20),
                        Colors.transparent,
                        Colors.black.withAlpha(42),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildMapLabels(),
            Positioned(
              left: 18,
              right: 18,
              top: 10,
              child: _buildTopRouteBar(),
            ),
            if (_stage != _BookRideStage.chat &&
                _stage != _BookRideStage.moreOptions)
              Positioned(
                right: 18,
                bottom: _bottomPanelHeight + 22,
                child: _circleIconButton(
                  icon: Icons.gps_fixed_rounded,
                  onTap: _recenterOnPickup,
                  light: true,
                ),
              ),
            _buildBottomPanel(),
            if (_isRefreshingRoute)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withAlpha(28),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: _yellow,
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

  double get _bottomPanelHeight {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return screenHeight * _panelHeightFactor;
  }

  double get _panelHeightFactor {
    switch (_stage) {
      case _BookRideStage.selectRide:
        return _showAllPaymentOptions ? 0.62 : 0.44;
      case _BookRideStage.pickup:
        return 0.31;
      case _BookRideStage.pickupSearch:
        return 0.62;
      case _BookRideStage.driverFound:
        return 0.38;
      case _BookRideStage.arriving:
        return 0.32;
      case _BookRideStage.moreOptions:
        return 0.82;
      case _BookRideStage.chat:
        return 0.84;
      case _BookRideStage.rideArrived:
        return 0.38;
      case _BookRideStage.driving:
        return 0.36;
      case _BookRideStage.paymentSummary:
      case _BookRideStage.review:
      case _BookRideStage.reviewSuccess:
      case _BookRideStage.cancelReasons:
        return 0;
    }
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: SizedBox(
          key: ValueKey('${_stage.name}_$_showAllPaymentOptions'),
          height: _bottomPanelHeight,
          child: _currentPanel(),
        ),
      ),
    );
  }

  Widget _currentPanel() {
    switch (_stage) {
      case _BookRideStage.selectRide:
        return _buildSelectRideSheet();
      case _BookRideStage.pickup:
        return _buildPickupSheet();
      case _BookRideStage.pickupSearch:
        return _buildPickupSearchSheet();
      case _BookRideStage.driverFound:
        return _buildDriverFoundSheet();
      case _BookRideStage.arriving:
        return _buildArrivingSheet();
      case _BookRideStage.moreOptions:
        return _buildMoreOptionsSheet();
      case _BookRideStage.chat:
        return _buildChatSheet();
      case _BookRideStage.rideArrived:
        return _buildRideArrivedSheet();
      case _BookRideStage.driving:
        return _buildDrivingSheet();
      case _BookRideStage.paymentSummary:
      case _BookRideStage.review:
      case _BookRideStage.reviewSuccess:
      case _BookRideStage.cancelReasons:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectRideSheet() {
    return _darkSheet(
      child: Column(
        children: [
          _dragHandle(),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var i = 0; i < _rideChoices.length; i++) ...[
                  _rideChoiceCard(index: i, choice: _rideChoices[i]),
                  if (i != _rideChoices.length - 1) const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
                _paymentOptions(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _primaryButton('Continue', _handleRidePayment),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupSheet() {
    return _darkSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(
          children: [
            _dragHandle(),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select pickup location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _setStage(_BookRideStage.pickupSearch),
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fromLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '₦3,500',
                  style: TextStyle(
                    color: _yellow,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mid-size Car',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
            const Spacer(),
            _primaryButton('Confirm Order', () {
              _setStage(_BookRideStage.driverFound);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupSearchSheet() {
    return _darkSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            const SizedBox(height: 18),
            _searchField(
              hint: 'Search your pickup location',
              onBack: () => _setStage(_BookRideStage.pickup),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: _pickupChoices.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFF262626)),
                itemBuilder: (context, index) {
                  final label = _pickupChoices[index];
                  return _locationChoiceRow(
                    title: label,
                    subtitle: index == 0
                        ? ''
                        : index == 1
                        ? 'Nigeria'
                        : 'Dawson Road, Benin City',
                    icon: index == 0
                        ? Icons.my_location_rounded
                        : index == 3
                        ? Icons.directions_bus_rounded
                        : Icons.location_on_rounded,
                    onTap: () => _applyPickupChoice(label),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverFoundSheet() {
    return _darkSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(
          children: [
            _dragHandle(),
            const SizedBox(height: 18),
            const Text(
              'Driver found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for driver to confirm the order',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: 0.62,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(_yellow),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _driverAvatar(),
                _roundSheetAction(
                  icon: Icons.edit_rounded,
                  label: 'Edit pickup',
                  onTap: () => _setStage(_BookRideStage.pickupSearch),
                ),
                _roundSheetAction(
                  icon: Icons.close_rounded,
                  label: 'Cancel Ride',
                  onTap: _showCancelRideConfirmation,
                  danger: true,
                ),
              ],
            ),
            const Spacer(),
            _primaryButton(
              'Confirm Order',
              () => _setStage(_BookRideStage.arriving),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivingSheet() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < 0) {
          _setStage(_BookRideStage.moreOptions);
        }
      },
      child: _darkSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _setStage(_BookRideStage.moreOptions),
                child: _dragHandle(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 36),
                  const Expanded(
                    child: Text(
                      'Arriving in 2 mins',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _circleIconButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: () => _setStage(_BookRideStage.moreOptions),
                    size: 34,
                    dark: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _driverInfoRow(),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _messageField(
                      onTap: () => _setStage(_BookRideStage.chat),
                      hint: 'Any pickup notes?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  _phoneButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOptionsSheet() {
    return _darkSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _setStage(_BookRideStage.arriving),
              child: _dragHandle(),
            ),
            const SizedBox(height: 14),
            _driverInfoRow(compact: false),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Text(
                    'My route',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _routePointRow(_fromLabel, _yellow, editable: true),
                  _routeConnector(),
                  _routePointRow('Add stop', const Color(0xFFFF981F)),
                  _routeConnector(),
                  _routePointRow(_toLabel, _yellow, editable: true),
                  const SizedBox(height: 20),
                  _optionTile(
                    icon: Icons.edit_location_alt_rounded,
                    title: 'Edit Destinations',
                    onTap: _editRoute,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _paymentSummaryRow(),
                  const SizedBox(height: 18),
                  const Text(
                    'More',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _optionTile(
                    icon: Icons.share_rounded,
                    title: 'Share ride details',
                    onTap: _showShareRideSheet,
                  ),
                  _optionTile(
                    imageAsset: 'images/chat.png',
                    title: 'Contact driver',
                    onTap: () => _setStage(_BookRideStage.chat),
                  ),
                  _optionTile(
                    icon: Icons.car_crash_rounded,
                    title: 'Cancel ride',
                    onTap: _showCancelRideConfirmation,
                    danger: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSheet() {
    return _darkSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Column(
          children: [
            _dragHandle(),
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton(
                  onPressed: _closeRideFlowToRides,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('images/driver.png'),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Andrew Johnson',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Toyota Corolla Sedan - BEN931AP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                _phoneButton(size: 42),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _chatBubble(_messages[index]),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickReply("Hi, I'm on my way"),
                  _quickReply("I'm here"),
                  _quickReply('Hello'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _messageField(
                    controller: _messageController,
                    hint: 'Type your message',
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _sendMessage(_messageController.text),
                  customBorder: const CircleBorder(),
                  child: const CircleAvatar(
                    radius: 27,
                    backgroundColor: _yellow,
                    child: Icon(Icons.send_rounded, color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideArrivedSheet() {
    return _darkSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(
          children: [
            _dragHandle(),
            const SizedBox(height: 18),
            const Text(
              'Your ride has arrived',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _driverInfoRow(),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _messageField(
                    onTap: () => _setStage(_BookRideStage.chat),
                    hint: 'Any pickup notes?',
                  ),
                ),
                const SizedBox(width: 12),
                _phoneButton(),
              ],
            ),
            const SizedBox(height: 14),
            _primaryButton(
              'Start ride',
              () => _setStage(_BookRideStage.driving),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingSheet() {
    return _darkSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(
          children: [
            _dragHandle(),
            const SizedBox(height: 18),
            const Text(
              'Driving to destination',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _driverInfoRow(showPlateUnderName: true),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your driver is Andrew',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '20 finished rides',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
            const Spacer(),
            _primaryButton(
              'Continue',
              () => _setStage(_BookRideStage.paymentSummary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => _setStage(_BookRideStage.driving),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
              const SizedBox(height: 18),
              const Text(
                'Payment',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _paymentSummaryRow(price: '₦3500'),
              const Spacer(flex: 2),
              const Center(
                child: Text(
                  'How was your ride?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      index < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: _yellow,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Excellent!',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _reviewTags
                    .map(
                      (tag) =>
                          _reviewTagChip(tag, selected: tag == 'Safe driving'),
                    )
                    .toList(),
              ),
              const Spacer(flex: 3),
              _primaryButton('Done', () => _setStage(_BookRideStage.review)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _setStage(_BookRideStage.paymentSummary),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Review',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _reviewController,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Write your review',
                  hintStyle: const TextStyle(color: _muted),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: Color(0xFFCECECE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: _yellow, width: 1.6),
                  ),
                ),
              ),
              const Spacer(),
              _primaryButton(
                'Continue',
                () => _setStage(_BookRideStage.reviewSuccess),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSuccessScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 58,
                ),
              ),
              const SizedBox(height: 42),
              const Text(
                'Review successfully submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(flex: 3),
              _primaryButton('Back To Home', _closeRideFlowToRides),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelReasonScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _setStage(_BookRideStage.moreOptions),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'What went wrong?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _cancelReasons.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFF6A6A6A)),
                  itemBuilder: (context, index) {
                    final selected = index == _selectedCancelReason;
                    return InkWell(
                      onTap: () =>
                          setState(() => _selectedCancelReason = index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _cancelReasons[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: selected ? _yellow : _line,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedCancelReason != null) ...[
                const SizedBox(height: 16),
                _primaryButton('Submit', _submitCancelReason),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _rideChoiceCard({required int index, required RideChoice choice}) {
    final selected = _selectedRide == index;

    return InkWell(
      onTap: () => setState(() => _selectedRide = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _yellow : const Color(0xFF444444),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              choice.image,
              width: 76,
              height: 46,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choice.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    choice.subtitle,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        choice.time,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.groups_rounded, color: _muted, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        choice.seats,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  choice.price,
                  style: const TextStyle(
                    color: _yellow,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  choice.oldPrice,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: _muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _showAllPaymentOptions ? 'Payment Options' : 'Select payment Options',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _paymentOptionRow(
          index: 0,
          image: 'images/cash.png',
          title: 'Cash',
          subtitle: 'Pay with cash',
          trailing: _showAllPaymentOptions
              ? null
              : IconButton(
                  onPressed: () =>
                      setState(() => _showAllPaymentOptions = true),
                  icon: const Icon(Icons.chevron_right_rounded, color: _muted),
                ),
        ),
        if (_showAllPaymentOptions) ...[
          _paymentOptionRow(
            index: 1,
            image: 'images/wallet2.png',
            title: 'CitiRide Wallet',
            subtitle: 'Bal: ₦${WalletBalance.balance.toStringAsFixed(0)}',
            action: '+ Top up wallet',
            onActionTap: () => Navigator.pushNamed(context, '/top-up'),
          ),
          _paymentOptionRow(
            index: 2,
            image: 'images/card.png',
            title: 'Bank Card',
            subtitle: '5678-2272-2837-2839',
            action: '+ Add debit card',
            onActionTap: () => Navigator.pushNamed(context, '/add-card'),
          ),
        ],
      ],
    );
  }

  Widget _paymentOptionRow({
    required int index,
    required String image,
    required String title,
    required String subtitle,
    Widget? trailing,
    String? action,
    VoidCallback? onActionTap,
  }) {
    final selected = _selectedPayment == index;

    return InkWell(
      onTap: () => setState(() => _selectedPayment = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Image.asset(image, width: 26, height: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                      if (action != null)
                        InkWell(
                          onTap: onActionTap,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _yellow.withAlpha(36),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              action,
                              style: const TextStyle(
                                color: _yellow,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? _yellow : _line,
                  size: 22,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRouteBar() {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.close_rounded,
          onTap: () => Navigator.pop(context),
          dark: true,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: _editRoute,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(158),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withAlpha(178)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      _compactPlace(_fromLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: _yellow,
                      size: 17,
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Text(
                      _compactPlace(_toLabel, destination: true),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _circleIconButton(
          icon: Icons.add_rounded,
          onTap: _editRoute,
          dark: true,
        ),
      ],
    );
  }

  Widget _buildMapLabels() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return IgnorePointer(
          ignoring: false,
          child: Stack(
            children: [
              Positioned(
                top: height * 0.18,
                right: width * 0.15,
                child: _mapPill(
                  _stage == _BookRideStage.arriving
                      ? 'Arrive by 10:53am'
                      : 'Arrive by 10:53am',
                ),
              ),
              Positioned(
                top: height * 0.34,
                left: width * 0.28,
                child: _mapPill('4 mins', compact: true),
              ),
              Positioned(
                top: height * 0.44,
                left: width * 0.30,
                child: InkWell(
                  onTap: () => _setStage(_BookRideStage.pickupSearch),
                  borderRadius: BorderRadius.circular(16),
                  child: _mapPill(
                    _stage == _BookRideStage.driverFound ||
                            _stage == _BookRideStage.arriving ||
                            _stage == _BookRideStage.rideArrived ||
                            _stage == _BookRideStage.driving
                        ? 'Tap to edit'
                        : 'Pickup Here',
                  ),
                ),
              ),
              Positioned(
                top: height * 0.30,
                left: width * 0.10,
                child: _mapCar(angle: -0.45),
              ),
              Positioned(
                top: height * 0.54,
                right: width * 0.26,
                child: _mapCar(angle: 0.62),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mapPill(String text, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: _yellow,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(34),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _mapCar({required double angle}) {
    return Transform.rotate(
      angle: angle,
      child: Image.asset(
        'images/car.png',
        width: 30,
        height: 42,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _darkSheet({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(118),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 52,
        height: 5,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _dangerButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _danger,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 44,
    bool light = false,
    bool dark = false,
  }) {
    final color = light
        ? const Color(0xFFF8F8F8)
        : dark
        ? Colors.black.withAlpha(168)
        : Colors.white;
    final iconColor = light || !dark ? Colors.black : Colors.white;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: dark ? Border.all(color: Colors.white.withAlpha(186)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(32),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.48),
      ),
    );
  }

  Widget _chatAssetIcon({double size = 20, Color? color}) {
    return Image.asset(
      'images/chat.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
    );
  }

  Widget _driverAvatar() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 27,
          backgroundImage: AssetImage('images/driver.png'),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _yellow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: Colors.black, size: 12),
              SizedBox(width: 2),
              Text(
                '4.9',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roundSheetAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(38),
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: danger ? const Color(0xFFFFC9C9) : Colors.white,
            child: Icon(icon, color: danger ? _danger : Colors.black, size: 25),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: danger ? _danger : _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverInfoRow({
    bool compact = true,
    bool showPlateUnderName = false,
  }) {
    return Row(
      children: [
        _driverAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Andrew Johnson',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: const TextSpan(
                  style: TextStyle(fontSize: 12, color: _muted),
                  children: [
                    TextSpan(
                      text: 'Green',
                      style: TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: ' · Toyota Corolla Sedan'),
                  ],
                ),
              ),
              if (showPlateUnderName || !compact) ...[
                const SizedBox(height: 5),
                _plateBadge(),
              ],
            ],
          ),
        ),
        if (compact) _plateBadge(),
      ],
    );
  }

  Widget _plateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'BEN931AP',
        style: TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _messageField({
    TextEditingController? controller,
    String hint = 'Any pickup notes?',
    VoidCallback? onTap,
    ValueChanged<String>? onSubmitted,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: controller == null ? _surfaceAlt : Colors.black,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: controller == null ? const Color(0xFFCFCFCF) : _yellow,
          ),
        ),
        child: Row(
          children: [
            _chatAssetIcon(size: 19, color: _muted),
            const SizedBox(width: 9),
            Expanded(
              child: controller == null
                  ? Text(
                      hint,
                      style: const TextStyle(color: _muted, fontSize: 14),
                    )
                  : TextField(
                      controller: controller,
                      onSubmitted: onSubmitted,
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: const TextStyle(color: _muted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        isDense: true,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneButton({double size = 56}) {
    return InkWell(
      onTap: () {},
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFD6FFD1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.phone_rounded,
          color: Color(0xFF0DB63D),
          size: 25,
        ),
      ),
    );
  }

  Widget _searchField({required String hint, required VoidCallback onBack}) {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
          size: 38,
          dark: true,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: _muted, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationChoiceRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFEFEFEF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routePointRow(String label, Color color, {bool editable = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (editable)
          IconButton(
            onPressed: _editRoute,
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
          ),
      ],
    );
  }

  Widget _routeConnector() {
    return Container(
      height: 24,
      margin: const EdgeInsets.only(left: 7),
      width: 2,
      color: _line,
    );
  }

  Widget _optionTile({
    IconData? icon,
    String? imageAsset,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            if (imageAsset == null)
              Icon(icon, color: danger ? _danger : Colors.white, size: 20)
            else
              _chatAssetIcon(size: 20, color: danger ? _danger : Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: danger ? _danger : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: danger ? _danger : _muted),
          ],
        ),
      ),
    );
  }

  Widget _paymentSummaryRow({String price = '₦2,900'}) {
    return Row(
      children: [
        Image.asset('images/cash.png', width: 24, height: 24),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Cash',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _chatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? _yellow : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.black : const Color(0xFF424242),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _quickReply(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _sendMessage(label),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewTagChip(String label, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? Colors.white : _line),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : _muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _ridePreviewCard({required double scale}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 82,
        height: 138,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('images/map.png', fit: BoxFit.cover),
                    Center(child: _mapPill('Tap')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Andrew J.',
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  String _compactPlace(String label, {bool destination = false}) {
    final cleaned = label.trim();
    if (cleaned.isEmpty) {
      return destination ? 'Ring Road Bus Terminal' : 'Lagos St.';
    }
    if (cleaned.toLowerCase().contains('lagos')) return 'Lagos St.';
    if (cleaned.toLowerCase().contains('ring')) return 'Ring Road Bus Terminal';
    final comma = cleaned.indexOf(',');
    final first = comma == -1 ? cleaned : cleaned.substring(0, comma);
    return first.length > 18 ? '${first.substring(0, 16)}...' : first;
  }

  Widget _buildRideMap() {
    final isDarkMap = Theme.of(context).brightness == Brightness.dark;
    final points = _routePoints.isEmpty
        ? _buildBentRoutePoints(_fromLatLng, _toLatLng)
        : _routePoints;
    final mapKey =
        '${isDarkMap ? 'dark' : 'light'}_${_fromLatLng.latitude}_${_fromLatLng.longitude}_${_toLatLng.latitude}_${_toLatLng.longitude}_${points.length}';

    if (kIsWeb) {
      final from = osm.LatLng(_fromLatLng.latitude, _fromLatLng.longitude);
      final webPoints = points
          .map((point) => osm.LatLng(point.latitude, point.longitude))
          .toList();

      return fm.FlutterMap(
        key: ValueKey('ride_map_web_$mapKey'),
        options: fm.MapOptions(initialCenter: from, initialZoom: 14),
        children: [
          fm.TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/${isDarkMap ? 'dark_all' : 'light_all'}/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.citiride',
          ),
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(points: webPoints, color: _yellow, strokeWidth: 5),
            ],
          ),
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                point: from,
                width: 52,
                height: 52,
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
            ],
          ),
        ],
      );
    }

    return gmaps.GoogleMap(
      key: ValueKey('ride_map_mobile_$mapKey'),
      initialCameraPosition: gmaps.CameraPosition(
        target: _fromLatLng,
        zoom: 14,
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
      style: isDarkMap ? kGoogleMapGrayscaleStyle : null,
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: _fromLatLng,
          icon: _pickupMarkerIcon,
          anchor: const Offset(0.5, 1),
          infoWindow: gmaps.InfoWindow(title: 'Pickup', snippet: _fromLabel),
        ),
        gmaps.Marker(
          markerId: const gmaps.MarkerId('destination'),
          position: _toLatLng,
          icon: _destinationMarkerIcon,
          anchor: const Offset(0.5, 1),
          infoWindow: gmaps.InfoWindow(title: 'Destination', snippet: _toLabel),
        ),
      },
      polylines: {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          points: points,
          color: _yellow,
          width: 5,
        ),
      },
    );
  }
}

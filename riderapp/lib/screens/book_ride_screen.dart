import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../components/ride_modal.dart';
import '../components/ride_top_bar.dart';
import '../components/pickup_collapsed_sheet.dart';
import '../components/driver_found_sheet.dart';
import '../components/chat_sheet.dart';

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
  late final MapController _mapController;
  late final ScrollController _scrollController;

  RideFlowState _flowState = RideFlowState.enterRide;

  final LatLng _fromLatLng = const LatLng(6.5244, 3.3792);
  final LatLng _toLatLng = const LatLng(6.4654, 3.4064);

  late final LatLng _midPoint;
  

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _scrollController = ScrollController();

    _midPoint = LatLng(
      (_fromLatLng.latitude + _toLatLng.latitude) / 2,
      (_fromLatLng.longitude + _toLatLng.longitude) / 2,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SafeArea(
        child: Stack(
          children: [
            /// MAP
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _fromLatLng,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/dataviz-light/{z}/{x}/{y}.png?key=UY3s7vp83IS8KCNXj05u',
                  tileDimension: 512,
                  zoomOffset: -1,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_fromLatLng, _midPoint],
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                    Polyline(
                      points: [_midPoint, _toLatLng],
                      color: Colors.purple,
                      strokeWidth: 4,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _fromLatLng,
                      width: 40,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: _buildLocationMarker(),
                    ),
                    Marker(
                      point: _fromLatLng,
                      width: 70,
                      height: 26,
                      alignment: Alignment.bottomCenter,
                      child: _timePill(
                        text: '15 mins',
                        color: Colors.blue,
                      ),
                    ),
                    Marker(
                      point: _toLatLng,
                      width: 40,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: _buildDestinationMarker(),
                    ),
                    Marker(
                      point: _toLatLng,
                      width: 135,
                      height: 26,
                      alignment: Alignment.bottomCenter,
                      child: _timePill(
                        text: 'Arrive by 10:30 AM',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            /// TOP BAR
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: RideTopBar(
                fromLocation: 'Lagos Island',
                toLocation: widget.selectedDestination ?? 'Ikeja',
              ),
            ),

            /// BOTTOM SHEET (STATE DRIVEN)
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
                  child: _buildSheetContent(scrollController), // pass it here
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ───────────────── SHEET CONTENT SWITCHER ─────────────────

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



  /// ───────────────── HELPERS ─────────────────

  Widget _buildLocationMarker() => Image.asset(
        'images/location_pointer.png',
        width: 54,
        height: 54,
      );

  Widget _buildDestinationMarker() => Image.asset(
        'images/destination_pointer.png',
        width: 54,
        height: 54,
      );

  Widget _timePill({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

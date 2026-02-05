import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../components/ride_modal.dart';
import '../components/ride_top_bar.dart';

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

  // Hard-coded locations
  final LatLng _fromLatLng = const LatLng(6.5244, 3.3792); // Lagos Island
  final LatLng _toLatLng   = const LatLng(6.4654, 3.4064); // Ikeja

  late final LatLng _midPoint;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // midpoint for gradient effect
    _midPoint = LatLng(
      (_fromLatLng.latitude + _toLatLng.latitude) / 2,
      (_fromLatLng.longitude + _toLatLng.longitude) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SafeArea(
        child: Stack(
          children: [
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

                /// ROUTE (blue → purple)
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

                /// MARKERS + TIME PILLS
                MarkerLayer(
                  markers: [
                    // FROM
                    Marker(
                      point: _fromLatLng,
                      width: 40,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: _buildLocationMarker(),
                    ),

                    // FROM TIME
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

                    // TO
                    Marker(
                      point: _toLatLng,
                      width: 40,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: _buildDestinationMarker(),
                    ),

                    // ARRIVAL TIME
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

            /// BOTTOM SHEET
            DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.6,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return RideModal(scrollController: scrollController);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMarker() {
    return Image.asset(
      'images/location_pointer.png',
      width: 54,
      height: 54,
    );
  }

  Widget _buildDestinationMarker() {
    return Image.asset(
      'images/destination_pointer.png',
      width: 54,
      height: 54,
    );
  }

  /// Slim pill (tight fit)
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

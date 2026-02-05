import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../utils/location_manager.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final TextEditingController _destinationController = TextEditingController();
  List<Map<String, dynamic>> recentLocations = [];
  String _currentLocationText = 'Getting your location...';
  bool _showBookRideButton = false;
  bool _isLoadingLocation = true;
  bool _isLoadingRecents = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadRecentLocations();
    LocationManager().addListener(_onLocationsUpdated);
  }

  void _onLocationsUpdated() {
    if (mounted) {
      setState(() => _isLoadingRecents = true);
      _loadRecentLocations();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks.first;
        String address = [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
        ].where((part) => part != null).join(', ');

        setState(() {
          _currentLocationText = address.isNotEmpty ? address : 'Current Location';
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentLocationText = 'Current Location';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _currentLocationText = 'Unable to get location';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadRecentLocations() async {
    try {
      final loadedLocations = await LocationManager().getRecentLocations();
      setState(() {
        recentLocations = loadedLocations;
        _isLoadingRecents = false;
      });
    } catch (e) {
      print('Error loading recent locations: $e');
      setState(() {
        recentLocations = [];
        _isLoadingRecents = false;
      });
    }
  }

  Future<void> _addRecentLocation(String name, String address) async {
    await LocationManager().addRecentLocation(name, address);
  }

  void _bookRide() async {
    if (_destinationController.text.isEmpty) return;

    setState(() => _isBooking = true);

    await _addRecentLocation('Destination', _destinationController.text);

    await Future.delayed(const Duration(seconds: 1)); // simulate booking delay

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/bookride',
      arguments: {
        'destination': _destinationController.text,
        'currentLocation': _currentLocationText,
        'pickupTime': DateTime.now().add(const Duration(minutes: 5)),
      },
    ).then((_) {
      setState(() {
        _destinationController.clear();
        _showBookRideButton = false;
        _isBooking = false;
      });
    });
  }

  @override
  void dispose() {
    LocationManager().removeListener(_onLocationsUpdated);
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final prefilledDestination = args?['prefilledDestination'];

    if (prefilledDestination != null && _destinationController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _destinationController.text = prefilledDestination;
            _showBookRideButton = prefilledDestination.isNotEmpty;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          "Your Route",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Location
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Your Location',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: _isLoadingLocation
                        ? Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Getting location...',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _currentLocationText,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Destination Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        hintText: 'Where do you want to go?',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _showBookRideButton = value.isNotEmpty;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.map_outlined, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Recent Locations Header
            if (recentLocations.isNotEmpty && !_isLoadingRecents)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Recent Locations',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            // Recent Locations List
            Expanded(
              child: _isLoadingRecents
                  ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                  : recentLocations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_history, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No recent destinations',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your recent ride destinations will appear here',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: recentLocations.length,
                          itemBuilder: (context, index) {
                            final location = recentLocations[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8), // closer spacing
                              child: RecentLocationItem(
                                name: location['name'] ?? 'Destination',
                                address: location['address'] ?? '',
                                noShadow: index == 0,
                                onTap: () {
                                  _destinationController.text = location['address'] ?? '';
                                  setState(() => _showBookRideButton = true);
                                },
                              ),
                            );
                          },
                        ),
            ),
            // Book Ride Button
            if (_showBookRideButton)
              Center(
                child: SizedBox(
                  width: 353,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _bookRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _isBooking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Book Ride',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
}

// RecentLocationItem Widget
class RecentLocationItem extends StatelessWidget {
  final String name;
  final String address;
  final bool noShadow;
  final VoidCallback onTap;

  const RecentLocationItem({
    super.key,
    required this.name,
    required this.address,
    this.noShadow = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // slimmer
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: noShadow
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            Text(address, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

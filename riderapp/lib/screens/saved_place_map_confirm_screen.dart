import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as osm;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_place_type.dart';
import 'saved_place_success_screen.dart';

class SavedPlaceMapConfirmScreen extends StatefulWidget {
  const SavedPlaceMapConfirmScreen({
    super.key,
    required this.placeType,
    required this.selectedAddress,
    required this.initialTarget,
  });

  final SavedPlaceType placeType;
  final String selectedAddress;
  final gmaps.LatLng initialTarget;

  @override
  State<SavedPlaceMapConfirmScreen> createState() =>
      _SavedPlaceMapConfirmScreenState();
}

class _SavedPlaceMapConfirmScreenState extends State<SavedPlaceMapConfirmScreen> {
  late gmaps.LatLng _selectedLatLng;
  bool _alwaysUseThisLocation = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedLatLng = widget.initialTarget;
  }

  Future<void> _savePlace() async {
    if (_saving) return;
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    final key = widget.placeType.key;

    await prefs.setString('saved_place_${key}_address', widget.selectedAddress);
    await prefs.setDouble('saved_place_${key}_lat', _selectedLatLng.latitude);
    await prefs.setDouble('saved_place_${key}_lng', _selectedLatLng.longitude);
    await prefs.setBool(
      'saved_place_${key}_always_pickup',
      _alwaysUseThisLocation,
    );

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SavedPlaceSuccessScreen(placeType: widget.placeType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 14,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF2D2F3A),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Always pick me up when I'm at this location",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7D8088),
                          ),
                        ),
                      ),
                      Switch(
                        value: _alwaysUseThisLocation,
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                        onChanged: (value) {
                          setState(() => _alwaysUseThisLocation = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.selectedAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2D2F3A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF7D8088),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _savePlace,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (kIsWeb) {
      final center = osm.LatLng(
        _selectedLatLng.latitude,
        _selectedLatLng.longitude,
      );
      return fm.FlutterMap(
        options: fm.MapOptions(
          initialCenter: center,
          initialZoom: 16,
          onPositionChanged: (position, hasGesture) {
            final value = position.center;
            if (!hasGesture) return;
            setState(() {
              _selectedLatLng = gmaps.LatLng(value.latitude, value.longitude);
            });
          },
        ),
        children: [
          fm.TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.citiride',
          ),
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                point: center,
                width: 46,
                height: 46,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF2F323D),
                  size: 42,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _selectedLatLng,
        zoom: 16,
      ),
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      onCameraMove: (position) {
        _selectedLatLng = position.target;
      },
      onCameraIdle: () => setState(() {}),
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('saved_place_pin'),
          position: _selectedLatLng,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
        ),
      },
    );
  }
}

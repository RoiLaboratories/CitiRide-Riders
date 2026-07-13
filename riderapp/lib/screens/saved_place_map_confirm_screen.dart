import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as osm;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_place_type.dart';
import '../theme/app_theme.dart';
import '../utils/google_map_style.dart';
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

class _SavedPlaceMapConfirmScreenState
    extends State<SavedPlaceMapConfirmScreen> {
  static const Color _sheet = Color(0xFF151515);
  static const Color _field = Color(0xFF242424);
  static const Color _muted = Color(0xFF9B9B9B);

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

  String get _shortAddress {
    final trimmed = widget.selectedAddress.trim();
    if (trimmed.isEmpty) return widget.placeType.title;
    return trimmed.split(',').first.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: Colors.black.withAlpha(34)),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: Image.asset(
                  'images/location_pin.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.location_on_rounded,
                    color: CitiRideTheme.primaryYellow,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 14,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF151515).withAlpha(184),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          Align(alignment: Alignment.bottomCenter, child: _bottomSheet()),
        ],
      ),
    );
  }

  Widget _bottomSheet() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        18 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: _sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 38,
            padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
            decoration: BoxDecoration(
              color: _field,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF474747)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Always pick me up when I'm at this location",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.72,
                  child: Switch(
                    value: _alwaysUseThisLocation,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF20DC5A),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFF555555),
                    onChanged: (value) {
                      setState(() => _alwaysUseThisLocation = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shortAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Drag map to set the default pick-up/drop-off location for\nthis saved place',
                      style: TextStyle(
                        color: Colors.white.withAlpha(152),
                        fontSize: 10,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFBDBDBD),
                  size: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _savePlace,
              style: ElevatedButton.styleFrom(
                backgroundColor: CitiRideTheme.primaryYellow,
                disabledBackgroundColor: CitiRideTheme.primaryYellow.withAlpha(
                  118,
                ),
                foregroundColor: Colors.black,
                disabledForegroundColor: Colors.black.withAlpha(140),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
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
                'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.citiride',
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
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      style: kGoogleMapGrayscaleStyle,
      onCameraMove: (position) {
        _selectedLatLng = position.target;
      },
      onCameraIdle: () => setState(() {}),
    );
  }
}

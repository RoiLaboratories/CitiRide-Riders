import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTopBar extends StatefulWidget {
  const HomeTopBar({
    super.key,
    this.onAvatarTap,
  });

  final VoidCallback? onAvatarTap;

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  String _locationText = 'Lagos';
  String _currentAddress = 'Getting location...';
  bool _isLoading = true;
  String? _profileAvatarAsset;
  Uint8List? _profileAvatarBytes;

  Uint8List? _decodeAvatarBase64(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _getCurrentLocation();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _profileAvatarAsset = prefs.getString('profile_avatar_asset');
      final avatarBase64 = (prefs.getString('profile_avatar_base64') ?? '').trim();
      _profileAvatarBytes = _decodeAvatarBase64(avatarBase64);
    });
  }

  Widget _buildAvatarImage() {
    if (_profileAvatarBytes != null && _profileAvatarBytes!.isNotEmpty) {
      return Image.memory(
        _profileAvatarBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.person,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    if (_profileAvatarAsset != null && _profileAvatarAsset!.trim().isNotEmpty) {
      return Image.asset(
        _profileAvatarAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.person,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    return const Icon(
      Icons.person,
      color: Colors.white,
      size: 24,
    );
  }


  Future<void> _getCurrentLocation() async {
    try {
      // Check for location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          _locationText = 'Permission Required';
          _currentAddress = 'Set location to enable';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      // Use geocoding package with the alias - CORRECT METHOD
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks.first;
        setState(() {
          _locationText = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
          _currentAddress = [
            if (place.street != null && place.street!.isNotEmpty) place.street,
            if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          ].where((part) => part != null).join(', ');
          
          if (_currentAddress.isEmpty) {
            _currentAddress = _locationText;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _locationText = 'Current Location';
          _currentAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _locationText = 'Location Error';
        _currentAddress = 'Unable to get location';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar with shadow - FIXED
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(128),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onAvatarTap != null) {
                  widget.onAvatarTap!.call();
                  return;
                }
                Navigator.pushNamed(context, '/profile').then((_) {
                  _loadProfileImage();
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Location Container
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 127),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE3F2FD),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue[700],
                      size: 18,
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your location',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _isLoading
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue[400],
                                ),
                              )
                            : Text(
                                _currentAddress,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Notification Icon
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(128),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/notifications');
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.notifications,
                        size: 22,
                        color: Colors.black,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          border: Border.fromBorderSide(
                            BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

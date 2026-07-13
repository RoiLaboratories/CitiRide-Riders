import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/google_maps_places_service.dart';
import '../theme/app_theme.dart';

class HomeTopBar extends StatefulWidget {
  const HomeTopBar({
    super.key,
    this.onAvatarTap,
    this.profileRefreshSeed = 0,
    this.locationRefreshSeed = 0,
  });

  final VoidCallback? onAvatarTap;
  final int profileRefreshSeed;
  final int locationRefreshSeed;

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  static const double _avatarSize = 44;

  String _locationText = 'Lagos';
  String _currentAddress = 'Getting location...';
  bool _isLoading = true;
  String? _profileAvatarAsset;
  Uint8List? _profileAvatarBytes;
  final GoogleMapsPlacesService _placesService = GoogleMapsPlacesService();

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

  @override
  void didUpdateWidget(covariant HomeTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.profileRefreshSeed != widget.profileRefreshSeed) {
      _loadProfileImage();
    }

    if (oldWidget.locationRefreshSeed != widget.locationRefreshSeed) {
      _getCurrentLocation();
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _profileAvatarAsset = prefs.getString('profile_avatar_asset');
      final avatarBase64 = (prefs.getString('profile_avatar_base64') ?? '')
          .trim();
      _profileAvatarBytes = _decodeAvatarBase64(avatarBase64);
    });
  }

  Widget _buildAvatarImage() {
    Widget defaultAvatar() {
      return Image.asset(
        'images/profile.png',
        width: _avatarSize,
        height: _avatarSize,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.person, color: Colors.white, size: 24),
      );
    }

    if (_profileAvatarBytes != null && _profileAvatarBytes!.isNotEmpty) {
      return Image.memory(
        _profileAvatarBytes!,
        width: _avatarSize,
        height: _avatarSize,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (_, _, _) => defaultAvatar(),
      );
    }

    if (_profileAvatarAsset != null && _profileAvatarAsset!.trim().isNotEmpty) {
      return Image.asset(
        _profileAvatarAsset!,
        width: _avatarSize,
        height: _avatarSize,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (_, _, _) => defaultAvatar(),
      );
    }

    return defaultAvatar();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          _locationText = 'Permission Required';
          _currentAddress = 'Allow location in browser settings';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;
      _locationText = 'Current Location';
      _currentAddress = 'Current location';
      _isLoading = false;

      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (!mounted || placemarks.isEmpty) {
          setState(() {});
          return;
        }

        final place = placemarks.first;
        setState(() {
          _locationText =
              place.locality ??
              place.subAdministrativeArea ??
              'Current Location';
          _currentAddress = [
            if (place.street != null && place.street!.isNotEmpty) place.street,
            if (place.subLocality != null && place.subLocality!.isNotEmpty)
              place.subLocality,
          ].where((part) => part != null).join(', ');

          if (_currentAddress.isEmpty) {
            _currentAddress = _locationText;
          }
          _isLoading = false;
        });
      } catch (_) {
        if (!mounted) return;

        final googleAddress = await _placesService.reverseGeocodeAddress(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        setState(() {
          if (kIsWeb) {
            _locationText = 'Browser Location';
          }
          _currentAddress =
              (googleAddress != null && googleAddress.trim().isNotEmpty)
              ? googleAddress.trim()
              : 'Current location';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      final lower = e.toString().toLowerCase();
      final permissionError =
          lower.contains('permission') || lower.contains('denied');

      setState(() {
        _locationText = permissionError
            ? 'Permission Required'
            : 'Location Error';
        _currentAddress = permissionError
            ? 'Allow location in browser settings'
            : 'Unable to get location';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleAddress = _currentAddress.trim().isEmpty
        ? _locationText
        : _currentAddress;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.citiRideColors;

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(46),
                blurRadius: 12,
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
            child: SizedBox(
              width: _avatarSize,
              height: _avatarSize,
              child: _buildAvatarImage(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 210),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xE6171717) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 80 : 24),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'images/pin.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Location',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  visibleAddress,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/notifications');
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: isDark ? const Color(0xFF171717) : Colors.white,
              child: Center(
                child: SvgPicture.asset(
                  isDark ? 'images/bell1.svg' : 'images/bell2.svg',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

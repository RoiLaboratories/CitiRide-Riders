import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';

import 'wallet_onboarding_flow.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as osm;
import 'package:shared_preferences/shared_preferences.dart';

import '../components/home_top_bar.dart';
import '../components/home_modal_sheet.dart';
import '../components/bottom_nav_bar.dart';
import '../components/location_permission_modal.dart';
import '../theme/app_theme.dart';
import '../screens/ride_screen.dart';
import '../screens/wallet_screen.dart';
import '../utils/google_map_style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _defaultNigerianPhone = '+2349070107455';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PageController _pageController;

  late int _currentIndex;
  bool _locationLoading = false;
  bool _isCheckingWalletPin = false;
  bool _isLocationModalOpen = false;
  String _drawerName = 'Rider';
  String _drawerUsername = '@user';
  String _drawerPhone = _defaultNigerianPhone;
  int _locationRefreshSeed = 0;
  int _profileRefreshSeed = 0;
  bool _isDrawerOpen = false;

  gmaps.LatLng _currentLocation = const gmaps.LatLng(6.5244, 3.3792);
  gmaps.BitmapDescriptor _userLocationMarkerIcon = gmaps
      .BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure);

  // ---------------- INIT ----------------

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex.clamp(0, 2);
    _pageController = PageController(initialPage: _currentIndex);
    _loadDrawerProfile();
    _loadUserLocationMarkerIcon();

    /// Show location modal only on Home tab after first frame.
    if (_currentIndex == 0) {
      WidgetsBinding.instance.addPostFrameCallback((ctx) {
        _showLocationPermissionModal();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentLocationForMap({
    required bool requestIfDenied,
  }) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestIfDenied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentLocation = gmaps.LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Could not refresh map location: $e');
    }
  }

  Future<void> _loadUserLocationMarkerIcon() async {
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
        _userLocationMarkerIcon = marker;
      });
    } catch (e) {
      debugPrint('Could not load location pointer marker: $e');
    }
  }

  Future<void> _loadDrawerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString('profile_name') ?? '').trim();
    final username = (prefs.getString('profile_username') ?? '').trim();
    final phone = (prefs.getString('profile_phone') ?? '').trim();
    final firebasePhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    if (!mounted) return;

    setState(() {
      _drawerName = name.isNotEmpty ? name : 'Rider';
      _drawerUsername = username.isNotEmpty ? '@$username' : '@user';
      _drawerPhone = phone.isNotEmpty
          ? phone
          : (firebasePhone.isNotEmpty ? firebasePhone : _defaultNigerianPhone);
    });
  }

  void _openProfileDrawer() {
    _loadDrawerProfile();
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _navigateFromDrawer(String route) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    await Navigator.pushNamed(context, route);
    if (!mounted) return;

    await _loadDrawerProfile();
    setState(() {
      _profileRefreshSeed++;
    });
  }

  Future<void> _signOutFromDrawer() async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
  }

  Widget _drawerMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color titleColor = Colors.white,
    Color iconColor = const Color(0xFF101010),
    Color iconBg = const Color(0xFFE6E6E6),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: iconBg,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9B9B9B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDrawer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.64,
      child: Drawer(
        elevation: 0,
        backgroundColor: const Color(0xFF171717),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.transparent,
                      backgroundImage: const AssetImage('images/profile.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _drawerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _drawerUsername,
                            style: const TextStyle(
                              fontSize: 14,
                              color: CitiRideTheme.primaryYellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _drawerPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9B9B9B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _drawerMenuTile(
                  icon: Icons.person,
                  title: 'Personal info',
                  subtitle: 'Edit your personal information',
                  onTap: () => _navigateFromDrawer('/profile'),
                ),
                const SizedBox(height: 4),
                _drawerMenuTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'Edit your settings',
                  onTap: () => _navigateFromDrawer('/settings'),
                ),
                const SizedBox(height: 4),
                _drawerMenuTile(
                  icon: Icons.bookmark,
                  title: 'Saved places',
                  subtitle: 'Enter your home and work location',
                  onTap: () => _navigateFromDrawer('/saved-places'),
                ),
                const SizedBox(height: 4),
                _drawerMenuTile(
                  icon: Icons.logout,
                  title: 'Log out',
                  subtitle: 'Log out from your account',
                  titleColor: const Color(0xFFFF3B3B),
                  iconColor: const Color(0xFFFF3B3B),
                  iconBg: const Color(0xFF2A1717),
                  onTap: _signOutFromDrawer,
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Want to earn as a driver?',
                              style: TextStyle(
                                fontSize: 14,
                                color: CitiRideTheme.primaryYellow,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Go to driver app',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFBDBDBD),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: CitiRideTheme.primaryYellow,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- LOCATION MODAL ----------------

  Future<void> _showLocationPermissionModal() async {
    if (_isLocationModalOpen) return;
    _isLocationModalOpen = true;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Location Permission',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withAlpha(82)),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
                  ),
                  child: LocationPermissionModal(
                    loading: _locationLoading,
                    onAllow: _requestLocationPermission,
                    onLater: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
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
    );

    _isLocationModalOpen = false;
  }

  Future<void> _requestLocationPermission() async {
    if (_locationLoading) return;

    setState(() => _locationLoading = true);

    try {
      if (_isLocationModalOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _isLocationModalOpen = false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      final hasPermission =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (!hasPermission) {
        final message = permission == LocationPermission.deniedForever
            ? 'Location permission is permanently denied. Enable it in settings.'
            : 'Location permission was not granted.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
        return;
      }

      setState(() {
        _locationRefreshSeed++;
      });

      await _refreshCurrentLocationForMap(requestIfDenied: false);
      if (!mounted) return;

      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      await _openWalletOnboarding(showWalletAfter: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not request location permission: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _locationLoading = false);
      }
    }
  }

  Future<bool> _openWalletOnboarding({required bool showWalletAfter}) async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool('wallet_onboarding_complete') ?? false;

    if (onboardingComplete) {
      if (showWalletAfter && mounted) {
        setState(() => _currentIndex = 2);
        _pageController.jumpToPage(2);
      }
      return true;
    }

    if (!mounted) return false;

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const WalletOnboardingFlow()),
    );

    if (!mounted) return completed == true;

    if (completed == true && showWalletAfter) {
      setState(() => _currentIndex = 2);
      _pageController.jumpToPage(2);
    }

    return completed == true;
  }

  // ---------------- TAB HANDLING ----------------

  Future<void> _onTabChanged(int index) async {
    if (index != 2) {
      setState(() => _currentIndex = index);
      _pageController.jumpToPage(index);
      return;
    }

    if (_isCheckingWalletPin) return;
    _isCheckingWalletPin = true;

    try {
      final ready = await _openWalletOnboarding(showWalletAfter: false);
      if (!mounted || !ready) return;

      setState(() => _currentIndex = index);
      _pageController.jumpToPage(index);
    } finally {
      _isCheckingWalletPin = false;
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isCompactHeight = size.height < 700;
    final horizontalInset = size.width < 360 ? 14.0 : 16.0;
    final topBarOffset = topInset + (isCompactHeight ? 12.0 : 18.0);
    final sheetTop = topInset + (isCompactHeight ? 74.0 : 82.0);
    final navBottom = bottomInset + (bottomInset > 0 ? 10.0 : 16.0);
    final sheetNavGap = isCompactHeight ? 20.0 : 26.0;
    final sheetBottom = navBottom + BottomNavBar.barHeight + sheetNavGap;
    final sheetAvailableHeight = size.height - sheetTop - sheetBottom;
    final collapsedSheetHeight = isCompactHeight ? 94.0 : 96.0;
    final collapsedSheetSize = (collapsedSheetHeight / sheetAvailableHeight)
        .clamp(0.16, 0.32)
        .toDouble();
    final expandedSnapSize = collapsedSheetSize < 0.60 ? 0.60 : 0.72;

    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      drawerScrimColor: Colors.transparent,
      onDrawerChanged: (isOpen) {
        if (_isDrawerOpen == isOpen) return;
        setState(() => _isDrawerOpen = isOpen);
      },
      drawer: _buildProfileDrawer(),
      body: Stack(
        children: [
          /// MAIN CONTENT (MAP + OTHER TABS)
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            children: [_buildHomeMap(), RideScreen(), WalletScreen()],
          ),

          /// TOP BAR
          if (_currentIndex != 2 && _currentIndex != 1) // hide in Wallet
            Positioned(
              top: topBarOffset,
              left: horizontalInset,
              right: horizontalInset,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(36),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: HomeTopBar(
                  onAvatarTap: _openProfileDrawer,
                  profileRefreshSeed: _profileRefreshSeed,
                  locationRefreshSeed: _locationRefreshSeed,
                ),
              ),
            ),

          /// HOME DRAGGABLE SHEET (ONLY HOME TAB)
          if (_currentIndex == 0)
            Positioned(
              left: horizontalInset,
              right: horizontalInset,
              bottom: sheetBottom,
              top: sheetTop,
              child: DraggableScrollableSheet(
                initialChildSize: collapsedSheetSize,
                minChildSize: collapsedSheetSize,
                maxChildSize: 0.82,
                snap: true,
                snapSizes: [collapsedSheetSize, expandedSnapSize],
                builder: (context, scrollController) {
                  return HomeModalSheet(scrollController: scrollController);
                },
              ),
            ),

          /// BOTTOM NAV BAR
          Positioned(
            left: 0,
            right: 0,
            bottom: navBottom,
            child: BottomNavBar(
              currentIndex: _currentIndex,
              onTabChanged: _onTabChanged,
            ),
          ),

          if (_isDrawerOpen)
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withAlpha(82)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- MAP ----------------

  Widget _buildHomeMap() {
    final isDarkMap = Theme.of(context).brightness == Brightness.dark;

    if (kIsWeb) {
      return fm.FlutterMap(
        key: ValueKey(
          'home_map_web_${isDarkMap ? 'dark' : 'light'}_${_currentLocation.latitude}_${_currentLocation.longitude}',
        ),
        options: fm.MapOptions(
          initialCenter: osm.LatLng(
            _currentLocation.latitude,
            _currentLocation.longitude,
          ),
          initialZoom: 15,
        ),
        children: [
          fm.TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/${isDarkMap ? 'dark_all' : 'light_all'}/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.citiride',
          ),
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                point: osm.LatLng(
                  _currentLocation.latitude,
                  _currentLocation.longitude,
                ),
                width: 46,
                height: 46,
                child: Image.asset(
                  'images/location_pointer.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return gmaps.GoogleMap(
      key: ValueKey(
        'home_map_mobile_${isDarkMap ? 'dark' : 'light'}_${_currentLocation.latitude}_${_currentLocation.longitude}',
      ),
      initialCameraPosition: gmaps.CameraPosition(
        target: _currentLocation,
        zoom: 15,
      ),
      mapType: gmaps.MapType.normal,
      compassEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      style: isDarkMap ? kGoogleMapGrayscaleStyle : null,
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('current_location'),
          position: _currentLocation,
          icon: _userLocationMarkerIcon,
          anchor: const Offset(0.5, 1),
          infoWindow: const gmaps.InfoWindow(title: 'Current location'),
        ),
      },
    );
  }
}

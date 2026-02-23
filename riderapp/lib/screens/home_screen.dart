import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/home_top_bar.dart';
import '../components/home_modal_sheet.dart';
import '../components/bottom_nav_bar.dart';
import '../components/location_permission_modal.dart';
import '../screens/ride_screen.dart';
import '../screens/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _defaultNigerianPhone = '+2349070107455';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  final MapController _mapController = MapController();

  int _currentIndex = 0;
  bool _locationLoading = false;
  bool _isCheckingWalletPin = false;
  String _drawerName = 'Rider';
  String _drawerUsername = '@user';
  String _drawerPhone = _defaultNigerianPhone;
  String? _drawerAvatarAsset;
  Uint8List? _drawerAvatarBytes;
  int _locationRefreshSeed = 0;
  int _profileRefreshSeed = 0;
  bool _isDrawerOpen = false;

  final LatLng _currentLocation = const LatLng(6.5244, 3.3792);

  Uint8List? _decodeAvatarBase64(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  // ---------------- INIT ----------------

  @override
  void initState() {
    super.initState();
    _loadDrawerProfile();

    /// Show location modal AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((ctx) {
      _showLocationPermissionModal();
    });
  }

  Future<void> _loadDrawerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString('profile_name') ?? '').trim();
    final username = (prefs.getString('profile_username') ?? '').trim();
    final phone = (prefs.getString('profile_phone') ?? '').trim();
    final avatarAsset = (prefs.getString('profile_avatar_asset') ?? '').trim();
    final avatarBase64 = (prefs.getString('profile_avatar_base64') ?? '')
        .trim();
    final firebasePhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    if (!mounted) return;

    setState(() {
      _drawerName = name.isNotEmpty ? name : 'Rider';
      _drawerUsername = username.isNotEmpty ? '@$username' : '@user';
      _drawerPhone = phone.isNotEmpty
          ? phone
          : (firebasePhone.isNotEmpty ? firebasePhone : _defaultNigerianPhone);
      _drawerAvatarAsset = avatarAsset.isNotEmpty ? avatarAsset : null;
      _drawerAvatarBytes = _decodeAvatarBase64(avatarBase64);
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

  ImageProvider? _getDrawerAvatarProvider() {
    if (_drawerAvatarBytes != null && _drawerAvatarBytes!.isNotEmpty) {
      return MemoryImage(_drawerAvatarBytes!);
    }
    if (_drawerAvatarAsset != null && _drawerAvatarAsset!.trim().isNotEmpty) {
      return AssetImage(_drawerAvatarAsset!);
    }
    return null;
  }

  Widget _drawerMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color titleColor = const Color(0xFF2D2F3A),
    Color iconColor = const Color(0xFF2D2F3A),
    Color iconBg = const Color(0xFFE3E4E6),
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
                      color: Color(0xFF80838A),
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
        backgroundColor: const Color(0xFFF2F2F4),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(44)),
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
                      backgroundColor: const Color(0xFFF6DCE8),
                      backgroundImage: _getDrawerAvatarProvider(),
                      child: _getDrawerAvatarProvider() == null
                          ? const Icon(
                              Icons.person,
                              size: 36,
                              color: Color(0xFF50525C),
                            )
                          : null,
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
                              color: Color(0xFF2D2F3A),
                            ),
                          ),
                          Text(
                            _drawerUsername,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0A84FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _drawerPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7D8088),
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
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved places will be available soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _drawerMenuTile(
                  icon: Icons.logout,
                  title: 'Log out',
                  subtitle: 'Log out from your account',
                  titleColor: const Color(0xFFFF3B3B),
                  iconColor: const Color(0xFFFF3B3B),
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
                    color: const Color(0xFFCEE6FA),
                    borderRadius: BorderRadius.circular(26),
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
                                color: Color(0xFF1082E4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Go to driver app',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1082E4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF1082E4),
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

  void _showLocationPermissionModal() {
    showGeneralDialog<void>(
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
                  child: Container(color: const Color(0x261E88E5)),
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
  }

  Future<void> _requestLocationPermission() async {
    if (_locationLoading) return;

    setState(() => _locationLoading = true);

    try {
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

      Navigator.of(context, rootNavigator: true).pop();
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
      final prefs = await SharedPreferences.getInstance();
      final pin = prefs.getString('wallet_pin') ?? '';

      if (!mounted) return;

      if (pin.isEmpty) {
        final result = await Navigator.pushNamed(context, '/create-wallet-pin');
        if (!mounted) return;

        if (result == true) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        }
        return;
      }

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

          if (_isDrawerOpen)
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: const Color(0x331E88E5)),
                ),
              ),
            ),

          /// TOP BAR
          if (_currentIndex != 2 && _currentIndex != 1) // hide in Wallet
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: HomeTopBar(
                key: ValueKey(
                  'home_top_bar_${_locationRefreshSeed}_$_profileRefreshSeed',
                ),
                onAvatarTap: _openProfileDrawer,
              ),
            ),

          /// HOME DRAGGABLE SHEET (ONLY HOME TAB)
          if (_currentIndex == 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 44,
              top: 150,
              child: DraggableScrollableSheet(
                initialChildSize: 0.30,
                minChildSize: 0.30,
                maxChildSize: 0.82,
                snap: true,
                snapSizes: const [0.30, 0.60],
                builder: (context, scrollController) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 56),
                    child: HomeModalSheet(scrollController: scrollController),
                  );
                },
              ),
            ),

          /// BOTTOM NAV BAR
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: BottomNavBar(
              currentIndex: _currentIndex,
              onTabChanged: _onTabChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MAP ----------------

  Widget _buildHomeMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.maptiler.com/maps/dataviz-light/{z}/{x}/{y}.png?key=UY3s7vp83IS8KCNXj05u',
          tileDimension: 512,
          zoomOffset: -1,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation,
              width: 40,
              height: 60,
              alignment: Alignment.topCenter,
              child: _buildLocationMarker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationMarker() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Image.asset('images/location_pointer.png', width: 54, height: 54),
    );
  }
}

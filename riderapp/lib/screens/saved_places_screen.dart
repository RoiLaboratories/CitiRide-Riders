import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_place_type.dart';
import '../theme/app_theme.dart';
import 'saved_place_search_screen.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  static const Color _bg = Color(0xFF101010);
  static const Color _row = Color(0xFF2B2B2B);
  static const Color _muted = Color(0xFF9B9B9B);

  String? _homeAddress;
  String? _officeAddress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
  }

  Future<void> _loadSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _homeAddress = (prefs.getString('saved_place_home_address') ?? '').trim();
      _officeAddress = (prefs.getString('saved_place_office_address') ?? '')
          .trim();
      _loading = false;
    });
  }

  Future<void> _openSearchFlow(SavedPlaceType type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedPlaceSearchScreen(placeType: type),
      ),
    );

    if (!mounted) return;
    await _loadSavedPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.pop(context),
              title: 'Saved places',
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: CitiRideTheme.primaryYellow,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
                      children: [
                        _savedPlaceRow(
                          type: SavedPlaceType.home,
                          subtitle: _homeAddress,
                        ),
                        const SizedBox(height: 12),
                        _savedPlaceRow(
                          type: SavedPlaceType.office,
                          subtitle: _officeAddress,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedPlaceRow({
    required SavedPlaceType type,
    required String? subtitle,
  }) {
    final subtitleText = (subtitle ?? '').trim();
    final hasSubtitle = subtitleText.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _openSearchFlow(type),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: _row,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.actionLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.title});

  final VoidCallback onBack;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 58),
        ],
      ),
    );
  }
}

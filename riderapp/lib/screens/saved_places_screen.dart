import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_place_type.dart';
import 'saved_place_search_screen.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
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
      _officeAddress =
          (prefs.getString('saved_place_office_address') ?? '').trim();
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
      backgroundColor: const Color(0xFFF2F2F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 24,
            color: Color(0xFF2D2F3A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved places',
          style: TextStyle(
            color: Color(0xFF2D2F3A),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1690F0)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                _savedPlaceRow(
                  type: SavedPlaceType.home,
                  subtitle: _homeAddress,
                ),
                const SizedBox(height: 4),
                _savedPlaceRow(
                  type: SavedPlaceType.office,
                  subtitle: _officeAddress,
                ),
              ],
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
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openSearchFlow(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.actionLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D2F3A),
                      ),
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7D8088),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Color(0xFF7D8088),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';

class HomeModalSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const HomeModalSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F2),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(24),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
        children: [
          _dragHandle(),
          const SizedBox(height: 12),

          // Search input (tappable)
          _searchInput(context),

          const SizedBox(height: 18),

          if (locations.isNotEmpty) ...[
            const Text(
              'Recent Locations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E313B),
              ),
            ),
            const SizedBox(height: 12),
            ...locations.map((location) {
              return _locationTile(
                name: location['name'] ?? '',
                address: location['address'] ?? '',
              );
            }),
          ],
        ],
      ),
    );
  }

  // ================= SEARCH INPUT =================

  Widget _searchInput(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/route');
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD3D3D6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE9EAED), width: 1.2),
        ),
        child: Row(
          children: [
            Image.asset(
              'images/search_icon.png',
              width: 24,
              height: 24,
              color: const Color(0xFF666A73),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Where are we going today?',
                style: const TextStyle(
                  color: Color(0xFF5D6168),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LOCATION TILE =================

  Widget _locationTile({
    required String name,
    required String address,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2F3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            address,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF80838A),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DRAG HANDLE =================

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFBCBDC2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

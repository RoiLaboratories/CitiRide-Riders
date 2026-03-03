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
        color: Colors.white,
        borderRadius: BorderRadius.circular(60), 
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          _dragHandle(),
          const SizedBox(height: 8),

          /// Search input (tappable)
          _searchInput(context),

          const SizedBox(height: 24),

          if (locations.isNotEmpty) ...[
            const Text(
              'Recent Locations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200, 
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Image.asset('images/search_icon.png', width: 24, height: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Where are we going today?',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
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
        color: Colors.grey.withValues(alpha: 15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            address,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
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
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 80),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

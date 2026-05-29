import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';

class HomeModalSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const HomeModalSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationProvider);
    final visibleLocations = locations.isNotEmpty
        ? locations.take(3).toList()
        : const [
            {'name': 'Benin City', 'address': 'Nigeria'},
            {
              'name': 'Afenmai Transport Company',
              'address': 'Dawson Road, Benin City',
            },
            {
              'name': 'Ring Road Bus Terminal',
              'address': 'Oba Market Road, Benin City 300102',
            },
          ];
    final colors = context.citiRideColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF2111111) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 130 : 28),
            blurRadius: 26,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          _dragHandle(),
          const SizedBox(height: 8),

          // Search input (tappable)
          _searchInput(context),

          const SizedBox(height: 26),

          ...visibleLocations.map((location) {
            return _locationTile(
              name: location['name'] ?? '',
              address: location['address'] ?? '',
              colors: colors,
            );
          }),
        ],
      ),
    );
  }

  // ================= SEARCH INPUT =================

  Widget _searchInput(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 360;
    final colors = context.citiRideColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/route');
      },
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171717) : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Image.asset(
              'images/search_icon.png',
              width: compact ? 24 : 26,
              height: compact ? 24 : 26,
              color: colors.mutedText,
            ),
            SizedBox(width: compact ? 12 : 18),
            Expanded(
              child: Text(
                'Where are we going today?',
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: compact ? 15.5 : 17,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                softWrap: false,
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
    required CitiRideThemeColors colors,
  }) {
    final icon = _locationIcon(name);

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4, bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: const Color(0xFF171717), size: 22),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: colors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
          color: CitiRideTheme.primaryYellow,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  IconData _locationIcon(String locationName) {
    final normalized = locationName.toLowerCase();

    if (normalized.contains('city')) {
      return Icons.access_time_filled_rounded;
    }

    if (normalized.contains('bus') || normalized.contains('terminal')) {
      return Icons.directions_bus_filled_rounded;
    }

    return Icons.location_on_rounded;
  }
}

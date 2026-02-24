import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBar extends StatelessWidget {
  final Function(int) onTabChanged;
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.onTabChanged,
    required this.currentIndex,
  });

  void _onItemTapped(int index) {
    if (currentIndex == index) return;
    onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: 208,
        margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 4),
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F36),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 90),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              index: 0,
              label: 'Home',
              iconAsset: 'images/home.png',
            ),
            _buildNavItem(
              index: 1,
              label: 'Ride',
              iconAsset: 'images/ride.png',
            ),
            _buildNavItem(
              index: 2,
              label: 'Wallet',
              iconAsset: 'images/wallet.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String iconAsset,
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 10 : 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A84FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(35),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0A84FF).withValues(alpha: 120),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconAsset,
              height: 50,
              width: 50,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 180),
            ),
            if (isSelected) ...[
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

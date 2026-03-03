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
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 246,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF252A3A),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(70),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String iconAsset,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 48,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1890F4) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconAsset,
              height: 34,
              width: 34,
              color: Colors.white.withAlpha(isSelected ? 255 : 205),
              colorBlendMode: BlendMode.srcIn,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
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

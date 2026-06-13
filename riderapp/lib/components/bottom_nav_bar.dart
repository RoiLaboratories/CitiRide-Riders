import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBar extends StatelessWidget {
  static const double barHeight = 50;

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final barWidth = (screenWidth * 0.54).clamp(208.0, 224.0).toDouble();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: barWidth,
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(90),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(
              context: context,
              index: 0,
              label: 'Home',
              selectedIconAsset: 'images/home.png',
              unselectedIconAsset: 'images/home2.png',
            ),
            _buildNavItem(
              context: context,
              index: 1,
              label: 'Ride',
              selectedIconAsset: 'images/ride.png',
              unselectedIconAsset: 'images/ride2.png',
            ),
            _buildNavItem(
              context: context,
              index: 2,
              label: 'Wallet',
              selectedIconAsset: 'images/wallet.png',
              unselectedIconAsset: 'images/wallet2.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required String selectedIconAsset,
    required String unselectedIconAsset,
  }) {
    final bool isSelected = currentIndex == index;
    final iconAsset = isSelected ? selectedIconAsset : unselectedIconAsset;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 38,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 10 : 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF101010) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconAsset,
              height: 26,
              width: 26,
              color: isSelected ? Colors.white : null,
              colorBlendMode: isSelected ? BlendMode.srcIn : null,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, _, _) => Icon(
                _fallbackIcon(index),
                size: 24,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: GoogleFonts.poppins(
                  fontSize: 11,
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

  IconData _fallbackIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.local_taxi_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RecentLocationItem extends StatelessWidget {
  final String name;
  final String address;
  final VoidCallback? onTap;

  const RecentLocationItem({
    super.key,
    required this.name,
    required this.address,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconColor(name),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(name),
                color: Colors.white,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Removed the dropdown arrow
            
            // Time indicator or favorite icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '1d ago',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String locationName) {
    switch (locationName.toLowerCase()) {
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      case 'gym':
        return Icons.fitness_center;
      case 'mall':
        return Icons.shopping_cart;
      default:
        return Icons.place;
    }
  }

  Color _getIconColor(String locationName) {
    switch (locationName.toLowerCase()) {
      case 'work':
        return CitiRideTheme.primaryYellow;
      case 'home':
        return Colors.green;
      case 'gym':
        return Colors.orange;
      case 'mall':
        return Colors.purple;
      default:
        return CitiRideTheme.primaryYellow;
    }
  }
}

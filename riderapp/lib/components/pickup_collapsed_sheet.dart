import 'package:flutter/material.dart';
import '../constants/ride_sheet_constants.dart';

class PickupCollapsedSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onSearchTap;
  final String pickupLabel;
  final String destinationLabel;

  const PickupCollapsedSheet({
    super.key,
    required this.onConfirm,
    required this.onSearchTap,
    required this.pickupLabel,
    required this.destinationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPickup = pickupLabel.trim().isEmpty
        ? 'Pickup location'
        : pickupLabel.trim();
    final resolvedDestination = destinationLabel.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: floatingSheetDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dragHandle(),
            const SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select pickup location',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Image.asset(
                    'images/pickup.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                  onPressed: onSearchTap,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                resolvedPickup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            ),

            if (resolvedDestination.isNotEmpty) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'To: $resolvedDestination',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextGrey,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 6),

            Row(
              children: const [
                Text(
                  'Mid-size Car',
                  style: TextStyle(color: kTextGrey),
                ),
                SizedBox(width: 12),
                Text(
                  '₦3,500',
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            primaryButton(
              text: 'Confirm Order',
              onTap: onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

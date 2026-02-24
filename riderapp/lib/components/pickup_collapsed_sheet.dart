import 'package:flutter/material.dart';
import '../constants/ride_sheet_constants.dart';

class PickupCollapsedSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onSearchTap;

  const PickupCollapsedSheet({
    super.key,
    required this.onConfirm,
    required this.onSearchTap, required scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                  icon: const Icon(Icons.search),
                  onPressed: onSearchTap,
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lagos Street',
                style: TextStyle(fontSize: 15),
              ),
            ),

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
import 'package:flutter/material.dart';
import '../constants/ride_sheet_constants.dart';

class DriverFoundSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final ScrollController scrollController;

  const DriverFoundSheet({
    super.key,
    required this.onConfirm,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: floatingSheetDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dragHandle(),
            const SizedBox(height: 18),

            const Text(
              'Driver found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Waiting for driver to confirm the order',
              style: TextStyle(color: kTextGrey),
            ),

            const SizedBox(height: 20),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Color(0xFFE6F0FF),
                valueColor: AlwaysStoppedAnimation(kPrimaryBlue),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _driverAvatar(),
                _circleAction(Icons.edit, 'Edit pickup'),
                _circleAction(Icons.close, 'Cancel Ride', red: true),
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

  Widget _driverAvatar() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundImage: AssetImage('images/driver.png'),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: kPrimaryBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '4.9',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _circleAction(IconData icon, String label, {bool red = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: red ? Colors.red.shade50 : kLightGrey,
          child: Icon(icon, color: red ? Colors.red : Colors.black),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

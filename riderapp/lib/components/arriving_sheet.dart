import 'package:flutter/material.dart';
import '../constants/ride_sheet_constants.dart';

class ArrivingSheet extends StatelessWidget {
  final VoidCallback onChatTap;

  const ArrivingSheet({super.key, required this.onChatTap});

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
            const SizedBox(height: 18),

            const Text(
              'Arriving in 2 mins',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/driver.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Andrew Johnson',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Green · Toyota Corolla Sedan',
                        style: TextStyle(color: Colors.green),
                      ),
                      SizedBox(height: 2),
                      Text('BEN931AP', style: TextStyle(color: kTextGrey)),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.phone, color: Colors.green),
                ),
              ],
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: onChatTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: kLightGrey,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'images/chat.png',
                      width: 20,
                      height: 20,
                      color: kTextGrey,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Any pickup notes?',
                      style: TextStyle(color: kTextGrey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

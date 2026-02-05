import 'package:flutter/material.dart';
import '../models/debit_card_model.dart';

class CardSelectorTile extends StatelessWidget {
  final DebitCard card;
  final VoidCallback onChange;

  const CardSelectorTile({
    super.key,
    required this.card,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5ECF3),
          width: 1.2,
        ),

      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage(card.logo),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.bankName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.maskedNumber,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onChange,
            child: Row(
              children: const [
                Text('Change',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(width: 6),
                Icon(Icons.chevron_right),
              ],
            ),
          )
        ],
      ),
    );
  }
}

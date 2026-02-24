import 'package:flutter/material.dart';

class AmountChip extends StatelessWidget {
  final int amount;
  final bool selected;
  final VoidCallback onTap;

  const AmountChip({
    super.key,
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color.fromARGB(255, 144, 211, 242) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          '₦${amount.toString()}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color:
              selected ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }
}

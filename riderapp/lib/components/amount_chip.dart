import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    final colors = context.citiRideColors;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.primaryBlur : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : colors.border,
          ),
        ),
        child: Text(
          '₦${amount.toString()}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: selected ? primary : colors.mutedText,
          ),
        ),
      ),
    );
  }
}

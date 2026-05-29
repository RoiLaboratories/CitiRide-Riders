import 'package:flutter/material.dart';

import '../models/nigerian_bank.dart';
import '../theme/app_theme.dart';

class BankLogo extends StatelessWidget {
  const BankLogo({
    super.key,
    required this.bank,
    this.size = 42,
    this.backgroundColor,
  });

  final NigerianBank bank;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surfaceAlt,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: bank.logoUrl == null
          ? _fallback(context)
          : Image.network(
              bank.logoUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _fallback(context),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _fallback(context);
              },
            ),
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = context.citiRideColors;
    final letters = bank.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first)
        .join()
        .toUpperCase();

    return Center(
      child: Text(
        letters.isEmpty ? '?' : letters,
        style: TextStyle(
          color: colors.text,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/wallet_balance.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _balanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final formattedBalance = '\u20A6${WalletBalance.balance.toStringAsFixed(0)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _balanceVisible ? formattedBalance : '\u20A6********',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A84FF),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Wallet Balance',
                style: TextStyle(
                  color: Color(0xFF0A84FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  setState(() => _balanceVisible = !_balanceVisible);
                },
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  _balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: const Color(0xFF0A84FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

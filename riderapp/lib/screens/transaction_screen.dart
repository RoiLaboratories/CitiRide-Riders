import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../components/transaction_tile.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  static const List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Payment to Ahmed',
      'time': '2:30 PM · Fri, 21 Jun 2025',
      'amount': '-₦435.54',
      'amountColor': Colors.red,
      'iconBg': Color(0xFFEFF3F6),
      'icon': Icons.person,
      'isCredit': false,
      'name': 'Ahmed Singer',
      'date': 'Fri, 21 Jun 2025',
      'clock': '2:30 PM',
    },
    {
      'title': 'Wallet Top Up',
      'time': '2:30 PM · Fri, 21 Jun 2025',
      'amount': '+₦435.54',
      'amountColor': Colors.green,
      'iconBg': Color(0xFFDFF5E1),
      'icon': Icons.arrow_downward,
      'isCredit': true,
      'name': 'Umoru Osigbemhe',
      'date': 'Fri, 21 Jun 2025',
      'clock': '2:30 PM',
      'accountNumber': '3748594032',
      'bank': 'UBA',
    },
    {
      'title': 'Transfer to Osi',
      'time': '2:30 PM · Fri, 21 Jun 2025',
      'amount': '-₦435.54',
      'amountColor': Colors.red,
      'iconBg': Color(0xFFFBE4E2),
      'icon': Icons.arrow_upward,
      'isCredit': false,
      'name': 'Osi Favor',
      'date': 'Fri, 21 Jun 2025',
      'clock': '2:30 PM',
    },
  ];

  void _openDetails(BuildContext context, Map<String, dynamic> transaction) {
    Navigator.pushNamed(
      context,
      '/transaction-details',
      arguments: {
        'title': transaction['title'],
        'amount': transaction['amount'],
        'isCredit': transaction['isCredit'],
        'name': transaction['name'],
        'date': transaction['date'],
        'time': transaction['clock'],
        'accountNumber': transaction['accountNumber'],
        'bank': transaction['bank'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<CitiRideThemeColors>()?.surface ?? const Color(0xFFF2F2F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 28,
            color: Color(0xFF2D2F3A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Color(0xFF2D2F3A),
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ListView(
          children: _transactions.map((transaction) {
            return TransactionTile(
              title: transaction['title'] as String,
              time: transaction['time'] as String,
              amount: transaction['amount'] as String,
              amountColor: transaction['amountColor'] as Color,
              iconBg: transaction['iconBg'] as Color,
              icon: transaction['icon'] as IconData,
              onTap: () => _openDetails(context, transaction),
            );
          }).toList(),
        ),
      ),
    );
  }
}

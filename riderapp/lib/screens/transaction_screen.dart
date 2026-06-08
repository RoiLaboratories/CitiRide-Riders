import 'package:flutter/material.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  static const List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Payment to Ahmed',
      'time': '2:30 PM - Fri, 21 Jun 2025',
      'amount': '-\u20A6435.54',
      'amountColor': Color(0xFFFF4343),
      'iconBg': Color(0xFFF3C2CD),
      'icon': Icons.person_rounded,
      'isCredit': false,
      'name': 'Ahmed Singer',
      'date': 'Fri, 21 Jun 2025',
      'clock': '2:30 PM',
    },
    {
      'title': 'Wallet Top Up',
      'time': '2:30 PM - Fri, 21 Jun 2025',
      'amount': '+\u20A6435.54',
      'amountColor': Color(0xFF24D05A),
      'iconBg': Color(0xFFD9F5DD),
      'icon': Icons.arrow_downward_rounded,
      'isCredit': true,
      'name': 'Umoru Osigbemhe',
      'date': 'Fri, 21 Jun 2025',
      'clock': '2:30 PM',
      'accountNumber': '3748594032',
      'bank': 'UBA',
    },
    {
      'title': 'Transfer to Osi',
      'time': '2:30 PM - Fri, 21 Jun 2025',
      'amount': '-\u20A6435.54',
      'amountColor': Color(0xFFFF4343),
      'iconBg': Color(0xFFF3C2CD),
      'icon': Icons.arrow_upward_rounded,
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
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Column(
          children: [
            _FlowHeader(
              title: 'Transactions',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                itemCount: _transactions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  return _TransactionTile(
                    title: transaction['title'] as String,
                    time: transaction['time'] as String,
                    amount: transaction['amount'] as String,
                    amountColor: transaction['amountColor'] as Color,
                    iconBg: transaction['iconBg'] as Color,
                    icon: transaction['icon'] as IconData,
                    onTap: () => _openDetails(context, transaction),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.title,
    required this.time,
    required this.amount,
    required this.amountColor,
    required this.iconBg,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String time;
  final String amount;
  final Color amountColor;
  final Color iconBg;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.black.withValues(alpha: 0.72)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9B9B9B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: TextStyle(
                color: amountColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

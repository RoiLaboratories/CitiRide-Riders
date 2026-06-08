import 'package:flutter/material.dart';

class WalletBalance {
  static double balance = 0;

  static final ValueNotifier<List<WalletTransaction>> transactions =
      ValueNotifier<List<WalletTransaction>>(
        List<WalletTransaction>.unmodifiable(_seedTransactions),
      );

  static void addTopUp(double amount) {
    if (amount <= 0) return;
    transactions.value = List<WalletTransaction>.unmodifiable([
      WalletTransaction.topUp(amount),
      ...transactions.value,
    ]);
  }

  static void addWithdrawal({
    required double amount,
    required String bank,
    required String accountNumber,
  }) {
    if (amount <= 0) return;
    transactions.value = List<WalletTransaction>.unmodifiable([
      WalletTransaction.withdrawal(
        amount: amount,
        bank: bank,
        accountNumber: accountNumber,
      ),
      ...transactions.value,
    ]);
  }

  static const List<WalletTransaction> _seedTransactions = [
    WalletTransaction(
      title: 'Payment to Ahmed',
      subtitle: '2:30 PM - Fri, 21 Jun 2025',
      amount: '-\u20A6435.54',
      amountColor: Color(0xFFFF4343),
      icon: Icons.person_rounded,
      avatarColor: Color(0xFFF3C2CD),
    ),
    WalletTransaction(
      title: 'Wallet Top Up',
      subtitle: '2:30 PM - Fri, 21 Jun 2025',
      amount: '+\u20A6435.54',
      amountColor: Color(0xFF24D05A),
      icon: Icons.arrow_downward_rounded,
      avatarColor: Color(0xFFD9F5DD),
      isCredit: true,
      accountNumber: '98291029281',
      bank: 'Paystack-Titan',
    ),
    WalletTransaction(
      title: 'Transfer to Osi',
      subtitle: '2:30 PM - Fri, 21 Jun 2025',
      amount: '-\u20A6435.54',
      amountColor: Color(0xFFFF4343),
      icon: Icons.arrow_upward_rounded,
      avatarColor: Color(0xFFF3C2CD),
    ),
  ];
}

@immutable
class WalletTransaction {
  const WalletTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.avatarColor,
    this.isCredit = false,
    this.accountNumber,
    this.bank,
  });

  factory WalletTransaction.topUp(double amount) {
    return WalletTransaction(
      title: 'Wallet Top Up',
      subtitle: _timestamp(),
      amount: '+\u20A6${amount.toStringAsFixed(2)}',
      amountColor: const Color(0xFF24D05A),
      icon: Icons.arrow_downward_rounded,
      avatarColor: const Color(0xFFD9F5DD),
      isCredit: true,
      accountNumber: '98291029281',
      bank: 'Paystack-Titan',
    );
  }

  factory WalletTransaction.withdrawal({
    required double amount,
    required String bank,
    required String accountNumber,
  }) {
    return WalletTransaction(
      title: 'Withdrawal to $bank',
      subtitle: _timestamp(),
      amount: '-\u20A6${amount.toStringAsFixed(2)}',
      amountColor: const Color(0xFFFF4343),
      icon: Icons.account_balance_rounded,
      avatarColor: const Color(0xFFF3C2CD),
      accountNumber: accountNumber,
      bank: bank,
    );
  }

  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color avatarColor;
  final bool isCredit;
  final String? accountNumber;
  final String? bank;

  static String _timestamp() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final meridiem = now.hour >= 12 ? 'PM' : 'AM';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '$hour:$minute $meridiem - ${weekdays[now.weekday - 1]}, '
        '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

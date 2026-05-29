import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        const {};

    final isCredit = args['isCredit'] == true;
    final title =
        (args['title'] as String?) ?? (isCredit ? 'Wallet Top Up' : 'Payment');
    final amount =
        (args['amount'] as String?) ??
        (isCredit ? '+\u20A60.00' : '-\u20A60.00');
    final date = (args['date'] as String?) ?? 'Fri, 21 Jun 2025';
    final time = (args['time'] as String?) ?? '2:30 PM';
    final name =
        (args['name'] as String?) ?? (isCredit ? 'Umoru Osigbemhe' : 'Rider');
    final accountNumber = (args['accountNumber'] as String?) ?? '3748594032';
    final bank = (args['bank'] as String?) ?? 'UBA';
    final amountColor = isCredit
        ? const Color(0xFF24D05A)
        : const Color(0xFFFF4343);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FlowHeader(
              title: 'Transaction details',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: isCredit
                                  ? const Color(0xFFD9F5DD)
                                  : const Color(0xFFF3C2CD),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCredit
                                  ? Icons.arrow_downward_rounded
                                  : Icons.person_rounded,
                              color: Colors.black.withValues(alpha: 0.72),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            amount,
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _DetailRow(label: 'Name', value: name),
                          if (isCredit) ...[
                            _DetailRow(
                              label: 'Account number',
                              value: accountNumber,
                            ),
                            _DetailRow(label: 'Bank', value: bank),
                          ],
                          _DetailRow(label: 'Date', value: date),
                          _DetailRow(label: 'Time', value: time),
                        ],
                      ),
                    ),
                    const Spacer(),
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

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return SizedBox(
      height: 58,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.text,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

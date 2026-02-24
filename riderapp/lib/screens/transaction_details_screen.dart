import 'package:flutter/material.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        const {};

    final bool isCredit = args['isCredit'] == true;
    final String title =
        (args['title'] as String?) ??
        (isCredit ? 'Wallet Top Up' : 'Payment to Ahmed');
    final String amount =
        (args['amount'] as String?) ?? (isCredit ? '+₦435.54' : '-₦435.54');
    final String date = (args['date'] as String?) ?? 'Fri, 21 Jun 2025';
    final String time = (args['time'] as String?) ?? '2:30 PM';
    final String name =
        (args['name'] as String?) ??
        (isCredit ? 'Umoru Osigbemhe' : 'Ahmed Singer');
    final String accountNumber =
        (args['accountNumber'] as String?) ?? '3748594032';
    final String bank = (args['bank'] as String?) ?? 'UBA';

    final Color amountColor = isCredit
        ? const Color(0xFF16B316)
        : const Color(0xFFFF3B3B);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
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
          'Transaction details',
          style: TextStyle(
            color: Color(0xFF2D2F3A),
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: isCredit
                    ? Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFCBEED0),
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 40,
                          color: Color(0xFF117E2A),
                        ),
                      )
                    : const CircleAvatar(
                        radius: 36,
                        backgroundImage: AssetImage('images/driver.png'),
                      ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2F3A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w500,
                    color: amountColor,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _detailRow('Name', name),
              if (isCredit) ...[
                const SizedBox(height: 22),
                _detailRow('Account number', accountNumber),
                const SizedBox(height: 22),
                _detailRow('Bank', bank),
              ],
              const SizedBox(height: 22),
              _detailRow('Date', date),
              const SizedBox(height: 22),
              _detailRow('Time', time),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF435057),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF435057),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

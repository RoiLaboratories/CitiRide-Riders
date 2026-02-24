import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WalletDetailsScreen extends StatelessWidget {
  const WalletDetailsScreen({super.key, required int amount,});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _paid(BuildContext context, double amount) {
  Navigator.pushNamed(
    context,
    '/verify-transfer',
    arguments: amount,
  );
}

  @override
  Widget build(BuildContext context) {
    final double amount =
      ModalRoute.of(context)!.settings.arguments as double;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Wallet details",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Amount", style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 5),
                  Text("₦${amount.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoRow(context, "Recipient's account name",
              "Sureride - Umoru Osigbemhe"),
            const Divider(),
            _buildInfoRow(context, "Account number", "98291029281"),
            const Divider(),
            _buildInfoRow(context, "Bank", "Paystack-titan"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _paid(context, amount),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("I have paid",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(title), Text(value)]),
          IconButton(
            onPressed: () => _copyToClipboard(context, value),
            icon: const Icon(Icons.copy, color: Colors.blue),
          )
        ],
      ),
    );
  }
}

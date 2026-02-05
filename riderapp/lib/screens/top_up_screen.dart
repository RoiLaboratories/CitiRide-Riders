import 'package:flutter/material.dart';
import '../models/debit_card_model.dart';
import '../components/amount_chip.dart';
import '../components/card_selector_tile.dart';
import '../components/change_card_sheet.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  int? selectedAmount;
  final TextEditingController _controller = TextEditingController();

  final card = DebitCard(
    bankName: 'Moniepoint',
    maskedNumber: '5064 8393 **** 4051',
    logo: 'images/moniepoint.png',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    final parsed = int.tryParse(value);
    setState(() {
      selectedAmount = parsed != null && parsed > 0 ? parsed : null;
    });
  }

  void _onChipSelected(int amount) {
    _controller.text = amount.toString(); // sync manual input
    setState(() => selectedAmount = amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Top Up',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Add money with your debit card directly',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),

            // Card selector
            CardSelectorTile(
              card: card,
              onChange: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (ctx) => ChangeCardSheet(card: card),
                );
              },
            ),

            const SizedBox(height: 30),
            const Text(
              'Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Manual input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              height: 54,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  border: InputBorder.none,
                  suffixIcon: selectedAmount != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() => selectedAmount = null);
                          },
                        )
                      : null,
                ),
                onChanged: _onAmountChanged,
              ),
            ),

            const SizedBox(height: 20),

            // Amount chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [2000, 5000, 10000]
                  .map(
                    (e) => AmountChip(
                      amount: e,
                      selected: selectedAmount == e,
                      onTap: () => _onChipSelected(e),
                    ),
                  )
                  .toList(),
            ),

            const Spacer(),

            // Fund Wallet button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: selectedAmount != null
                    ? () {
                        Navigator.pushNamed(
                          context,
                          '/verify-transfer',
                          arguments: {
                            'amount': selectedAmount!.toDouble(),
                            'topUp': true,
                          },
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedAmount != null
                      ? Colors.blue
                      : Colors.lightBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Fund Wallet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
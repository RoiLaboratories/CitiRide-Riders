import 'package:flutter/material.dart';
import '../components/amount_chip.dart';
import '../theme/app_theme.dart';
// import your CardSelectorTile & ChangeCardSheet properly
// import '../components/card_selector_tile.dart';
// import '../components/change_card_sheet.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  double? selectedAmount;

  void _continue() {
    if (selectedAmount == null) return;

    Navigator.pushNamed(
      context,
      '/wallet-detail',
      arguments: selectedAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.citiRideColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 22,
            color: colors.text,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bank Transfer',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Add money through bank transfer directly into your wallet',
                style: TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            /// Amount display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              height: 54,
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                selectedAmount == null
                    ? 'Enter amount'
                    : '₦${selectedAmount!.toStringAsFixed(0)}',
                style: TextStyle(
                  color: selectedAmount == null
                      ? colors.mutedText
                      : colors.text,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Amount chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [2000, 5000, 10000]
                  .map(
                    (e) => AmountChip(
                      amount: e,
                      selected: selectedAmount == e.toDouble(),
                      onTap: () {
                        setState(() => selectedAmount = e.toDouble());
                      },
                    ),
                  )
                  .toList(),
            ),

            const Spacer(),

            /// Continue button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: selectedAmount == null ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.primary.withValues(
                    alpha: 0.35,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimary,
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

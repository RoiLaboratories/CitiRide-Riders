import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  static const Color _bg = Color(0xFF101010);
  static const Color _panel = Color(0xFF181818);
  static const Color _yellow = CitiRideTheme.primaryYellow;
  static const Color _muted = Color(0xFF9B9B9B);

  final TextEditingController _amountController = TextEditingController();
  int? _selectedAmount;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    _amountController.text = amount.toString();
    setState(() {
      _selectedAmount = amount;
    });
  }

  void _onAmountChanged(String value) {
    final parsed = int.tryParse(value);
    setState(() {
      _selectedAmount = parsed != null && parsed > 0 ? parsed : null;
    });
  }

  void _continue() {
    final amount = _selectedAmount;
    if (amount == null) return;

    Navigator.pushNamed(
      context,
      '/wallet-detail',
      arguments: amount.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _FlowHeader(
              title: 'Bank transfer',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  18,
                  22,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.sizeOf(context).height -
                        MediaQuery.paddingOf(context).vertical -
                        110,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Add money through bank transfer directly into your wallet',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Amount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AmountInput(
                          controller: _amountController,
                          onChanged: _onAmountChanged,
                          onClear: () {
                            _amountController.clear();
                            setState(() => _selectedAmount = null);
                          },
                          showClear: _selectedAmount != null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _QuickAmountChip(
                              amount: 2000,
                              selected: _selectedAmount == 2000,
                              onTap: () => _setAmount(2000),
                            ),
                            const SizedBox(width: 8),
                            _QuickAmountChip(
                              amount: 5000,
                              selected: _selectedAmount == 5000,
                              onTap: () => _setAmount(5000),
                            ),
                            const SizedBox(width: 8),
                            _QuickAmountChip(
                              amount: 10000,
                              selected: _selectedAmount == 10000,
                              onTap: () => _setAmount(10000),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _TransferInfo(),
                        const Spacer(),
                        _PrimaryButton(
                          label: 'Verify',
                          onPressed: _selectedAmount == null ? null : _continue,
                        ),
                      ],
                    ),
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

class _AmountInput extends StatelessWidget {
  const _AmountInput({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          prefixText: '\u20A6 ',
          prefixStyle: const TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          hintText: 'Enter amount',
          hintStyle: const TextStyle(color: Color(0xFF7B7B7B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          suffixIcon: showClear
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, color: Colors.black),
                )
              : null,
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _TransferScreenState._yellow
                : _TransferScreenState._panel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _TransferScreenState._yellow
                  : const Color(0xFF333333),
            ),
          ),
          child: Text(
            '\u20A6$amount',
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferInfo extends StatelessWidget {
  const _TransferInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: CitiRideTheme.primaryYellow),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You will get a dedicated account to complete this transfer.',
              style: TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: CitiRideTheme.primaryYellow,
          disabledBackgroundColor: CitiRideTheme.primaryYellow.withValues(
            alpha: 0.42,
          ),
          foregroundColor: Colors.black,
          disabledForegroundColor: Colors.black.withValues(alpha: 0.52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

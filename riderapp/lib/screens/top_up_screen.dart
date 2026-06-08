import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
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

  void _fundWallet() {
    final amount = _selectedAmount;
    if (amount == null) return;

    Navigator.pushNamed(
      context,
      '/verify-transfer',
      arguments: {'amount': amount.toDouble(), 'topUp': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FlowHeader(
              title: 'Add money',
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
                            'Add money with your debit card directly',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _DebitCardTile(),
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
                        const Spacer(),
                        _PrimaryButton(
                          label: 'Fund wallet',
                          onPressed: _selectedAmount == null
                              ? null
                              : _fundWallet,
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

class _DebitCardTile extends StatelessWidget {
  const _DebitCardTile();

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CitiRideTheme.primaryYellow.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: CitiRideTheme.primaryYellow,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moniepoint',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '5064 8393 **** 4051',
                  style: TextStyle(color: colors.mutedText, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/add-card'),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                color: CitiRideTheme.primaryYellow,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
    final colors = context.citiRideColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _TopUpScreenState._yellow
                : (isDark ? _TopUpScreenState._panel : colors.surfaceAlt),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _TopUpScreenState._yellow
                  : colors.border,
            ),
          ),
          child: Text(
            '\u20A6$amount',
            style: TextStyle(
              color: selected ? Colors.black : colors.text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/bank_logo.dart';
import '../components/wallet_balance_card.dart';
import '../models/nigerian_bank.dart';
import '../models/wallet_balance.dart';
import '../services/nigerian_banks_service.dart';
import '../theme/app_theme.dart';

class WalletWithdrawalFlow extends StatefulWidget {
  const WalletWithdrawalFlow({super.key});

  @override
  State<WalletWithdrawalFlow> createState() => _WalletWithdrawalFlowState();
}

class _WalletWithdrawalFlowState extends State<WalletWithdrawalFlow> {
  static const Color _bg = Color(0xFF101010);
  static const Color _panel = Color(0xFF181818);
  static const Color _panelAlt = Color(0xFF242424);
  static const Color _muted = Color(0xFF9B9B9B);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _newAccountNumberController =
      TextEditingController();
  final TextEditingController _newAccountNameController =
      TextEditingController(text: 'Umoru Osigbemhe');
  int _step = 0;
  int _selectedAccount = 0;
  bool _processing = false;
  bool _hideBalance = false;

  static NigerianBank _bankByName(String name) {
    return NigerianBanksService.offlineBanks.firstWhere(
      (bank) => bank.name.toLowerCase().contains(name.toLowerCase()),
      orElse: () => NigerianBank(
        name: name,
        code: '',
        slug: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      ),
    );
  }

  final List<_WithdrawalAccount> _accounts = [
    _WithdrawalAccount(
      bank: _bankByName('Moniepoint'),
      number: '5064 8393 2937',
      name: 'Umoru Osigbemhe',
    ),
    _WithdrawalAccount(
      bank: _bankByName('First Bank'),
      number: '2243 5678 2837 1763',
      name: 'Umoru Osigbemhe',
    ),
    _WithdrawalAccount(
      bank: _bankByName('United Bank'),
      number: '3748 5940 32',
      name: 'Umoru Osigbemhe',
    ),
  ];

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _fee => _amount <= 0 ? 0 : 25;
  double get _receiveAmount => (_amount - _fee).clamp(0, double.infinity);
  bool get _canWithdraw =>
      _amount > 0 && _amount <= WalletBalance.balance && !_processing;

  @override
  void dispose() {
    _amountController.dispose();
    _newAccountNumberController.dispose();
    _newAccountNameController.dispose();
    super.dispose();
  }

  void _back() {
    if (_processing) return;
    if (_step > 0) {
      setState(() {
        _step -= 1;
      });
      return;
    }

    Navigator.pop(context);
  }

  void _continue() {
    if (_step == 0) {
      setState(() {
        _step = 1;
      });
    }
  }

  Future<void> _withdraw() async {
    if (!_canWithdraw) return;

    setState(() {
      _processing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));

    WalletBalance.balance = (WalletBalance.balance - _amount).clamp(
      0,
      double.infinity,
    );
    final account = _accounts[_selectedAccount];
    WalletBalance.addWithdrawal(
      amount: _amount,
      bank: account.bank.name,
      accountNumber: account.number,
    );

    if (!mounted) return;
    setState(() {
      _processing = false;
      _step = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              _FlowHeader(
                title: _step == 2 ? 'Transaction details' : 'Withdraw',
                onBack: _back,
                showBack: !_processing,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildAccountStep();
      case 1:
        return _buildAmountStep();
      default:
        return _buildSuccessStep();
    }
  }

  Widget _page({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }

  Widget _buildAccountStep() {
    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniWalletCard(
            balance: WalletBalance.balance,
            hidden: _hideBalance,
            onToggleVisibility: () =>
                setState(() => _hideBalance = !_hideBalance),
          ),
          const SizedBox(height: 22),
          const Text(
            'Select bank account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose where your withdrawal should be sent.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...List.generate(_accounts.length, (index) {
            final account = _accounts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AccountTile(
                account: account,
                selected: _selectedAccount == index,
                onTap: () => setState(() => _selectedAccount = index),
              ),
            );
          }),
          _AddAccountTile(onTap: _showAddBankSheet),
          const Spacer(),
          _PrimaryButton(label: 'Withdraw', onPressed: _continue),
        ],
      ),
    );
  }

  Widget _buildAmountStep() {
    final insufficient = _amount > WalletBalance.balance;
    final colors = context.citiRideColors;

    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniWalletCard(
            balance: WalletBalance.balance,
            hidden: _hideBalance,
            onToggleVisibility: () =>
                setState(() => _hideBalance = !_hideBalance),
          ),
          const SizedBox(height: 22),
          const Text(
            'Amount to withdraw',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                color: colors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixText: '\u20A6 ',
                prefixStyle: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                hintText: 'Enter amount',
                hintStyle: TextStyle(color: colors.mutedText),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
              ),
            ),
          ),
          if (insufficient) ...[
            const SizedBox(height: 8),
            const Text(
              'Insufficient wallet balance',
              style: TextStyle(
                color: Color(0xFFFF4343),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _QuickAmountChip(
                amount: 2000,
                selected: _amount == 2000,
                onTap: () => _setAmount(2000),
              ),
              const SizedBox(width: 8),
              _QuickAmountChip(
                amount: 5000,
                selected: _amount == 5000,
                onTap: () => _setAmount(5000),
              ),
              const SizedBox(width: 8),
              _QuickAmountChip(
                amount: 10000,
                selected: _amount == 10000,
                onTap: () => _setAmount(10000),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_amount > 0) _Breakdown(amount: _amount, fee: _fee),
          const Spacer(),
          _PrimaryButton(
            label: _processing ? 'Processing' : 'Withdraw money',
            loading: _processing,
            onPressed: _canWithdraw ? _withdraw : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    final account = _accounts[_selectedAccount];

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
            decoration: BoxDecoration(
              color: _panelAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF20DC5A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Transaction successful',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '-\u20A6${_amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFFF4343),
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _DetailRow(label: 'Name', value: account.name),
                _DetailRow(label: 'Bank', value: account.bank.name),
                _DetailRow(label: 'Account', value: account.number),
                _DetailRow(
                  label: 'You receive',
                  value: '\u20A6${_receiveAmount.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF20DC5A),
                ),
              ],
            ),
          ),
          const Spacer(),
          _PrimaryButton(
            label: 'Back to wallet',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  void _setAmount(int amount) {
    _amountController.text = amount.toString();
    setState(() {});
  }

  Future<void> _showAddBankSheet() async {
    final bank = await showModalBottomSheet<NigerianBank>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BankPickerSheet(
          onSelected: (selectedBank) =>
              Navigator.of(sheetContext).pop(selectedBank),
        );
      },
    );

    if (bank == null || !mounted) return;

    _newAccountNumberController.clear();
    final added = await showModalBottomSheet<_WithdrawalAccount>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;

        return Container(
          margin: EdgeInsets.fromLTRB(14, 0, 14, 18 + inset),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: _panelAlt,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                bank.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _SheetInput(
                controller: _newAccountNumberController,
                label: 'Account Number',
                hint: '2243 5678 2837 1763',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _SheetInput(
                controller: _newAccountNameController,
                label: 'Bank Name',
                hint: bank.name,
                readOnly: true,
              ),
              const SizedBox(height: 18),
              _PrimaryButton(
                label: 'Add bank',
                onPressed: () {
                  final number = _newAccountNumberController.text.trim();
                  if (number.length < 8) return;
                  Navigator.of(sheetContext).pop(
                    _WithdrawalAccount(
                      bank: bank,
                      number: number,
                      name: _newAccountNameController.text.trim(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (added == null || !mounted) return;
    setState(() {
      _accounts.add(added);
      _selectedAccount = _accounts.length - 1;
    });
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    required this.onBack,
    required this.showBack,
  });

  final String title;
  final VoidCallback onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return SizedBox(
      height: 58,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: showBack
                ? IconButton(
                    onPressed: onBack,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colors.text,
                      size: 18,
                    ),
                  )
                : null,
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

class _MiniWalletCard extends StatelessWidget {
  const _MiniWalletCard({
    required this.balance,
    required this.hidden,
    required this.onToggleVisibility,
  });

  final double balance;
  final bool hidden;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return WalletBalanceCard(balance: balance);
/*
    return Container(
      width: double.infinity,
      height: 126,
      decoration: BoxDecoration(
        color: CitiRideTheme.primaryYellow,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -26,
            child: Container(
              width: 138,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Balance',
                    style: TextStyle(
                      color: CitiRideTheme.primaryYellow,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hidden ? '\u20A6••••••' : '\u20A6${balance.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleVisibility,
                      icon: Icon(
                        hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
*/
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final _WithdrawalAccount account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? CitiRideTheme.primaryYellow.withValues(alpha: 0.14)
              : colors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? CitiRideTheme.primaryYellow
                : colors.border,
          ),
        ),
        child: Row(
          children: [
            BankLogo(bank: account.bank),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.bank.name,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${account.number} - ${account.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? CitiRideTheme.primaryYellow
                  : const Color(0xFF626262),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountTile extends StatelessWidget {
  const _AddAccountTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: CitiRideTheme.primaryYellow,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add another bank account',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CitiRideTheme.primaryYellow,
            ),
          ],
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

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? CitiRideTheme.primaryYellow
                : colors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? CitiRideTheme.primaryYellow
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

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.amount, required this.fee});

  final double amount;
  final double fee;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;
    final receive = (amount - fee).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'Amount',
            value: '\u20A6${amount.toStringAsFixed(2)}',
          ),
          _DetailRow(label: 'Fee', value: '\u20A6${fee.toStringAsFixed(2)}'),
          _DetailRow(
            label: 'You receive',
            value: '\u20A6${receive.toStringAsFixed(2)}',
            valueColor: const Color(0xFF20DC5A),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? colors.text,
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
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
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
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

class _WithdrawalAccount {
  const _WithdrawalAccount({
    required this.bank,
    required this.number,
    required this.name,
  });

  final NigerianBank bank;
  final String number;
  final String name;
}

/*
class _BankLogo extends StatelessWidget {
  const _BankLogo(this.name, {this.asset});

  final String name;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _brandColor(name),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Center(
              child: Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(asset!, fit: BoxFit.contain),
            ),
    );
  }

  Color _brandColor(String bankName) {
    final name = bankName.toLowerCase();
    if (name.contains('first')) return const Color(0xFF0C3C7C);
    if (name.contains('uba')) return const Color(0xFFE21A12);
    if (name.contains('gtbank')) return const Color(0xFFE66D11);
    if (name.contains('zenith')) return const Color(0xFFB71620);
    if (name.contains('access')) return const Color(0xFFEE6A23);
    if (name.contains('monie')) return const Color(0xFF0F6BEF);
    return const Color(0xFF202D46);
  }
}

class _NigerianBank {
  const _NigerianBank(this.name, {this.logoAsset});

  final String name;
  final String? logoAsset;
}

const List<_NigerianBank> _nigerianBanks = [
  _NigerianBank('Moniepoint', logoAsset: 'images/moniepoint.png'),
  _NigerianBank('First Bank'),
  _NigerianBank('UBA'),
  _NigerianBank('Access Bank'),
  _NigerianBank('GTBank'),
  _NigerianBank('Zenith Bank'),
  _NigerianBank('Fidelity Bank'),
  _NigerianBank('Sterling Bank'),
  _NigerianBank('Stanbic IBTC'),
  _NigerianBank('Wema Bank'),
  _NigerianBank('Union Bank'),
  _NigerianBank('Opay'),
  _NigerianBank('Kuda Bank'),
  _NigerianBank('PalmPay'),
];

*/
class _BankPickerSheet extends StatefulWidget {
  const _BankPickerSheet({required this.onSelected});

  final ValueChanged<NigerianBank> onSelected;

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  late final Future<List<NigerianBank>> _banksFuture =
      NigerianBanksService().fetchBanks();

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.68,
      ),
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.account_balance_rounded, color: colors.text),
              const SizedBox(width: 10),
              Text(
                'Select Bank',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<NigerianBank>>(
              future: _banksFuture,
              builder: (context, snapshot) {
                final banks =
                    snapshot.data ?? NigerianBanksService.offlineBanks;

                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: CitiRideTheme.primaryYellow,
                    ),
                  );
                }

                return ListView.separated(
                  itemBuilder: (context, index) {
                    final bank = banks[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: BankLogo(bank: bank),
                      title: Text(
                        bank.name,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        bank.code.isEmpty ? 'Nigeria' : 'Code ${bank.code}',
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () => widget.onSelected(bank),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemCount: banks.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetInput extends StatelessWidget {
  const _SheetInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.text, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: TextStyle(color: colors.text, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: colors.inputFill,
            hintStyle: TextStyle(color: colors.mutedText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

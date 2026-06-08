import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/profile_avatar.dart';
import '../components/wallet_balance_card.dart';
import '../models/wallet_balance.dart';
import '../theme/app_theme.dart';
import 'transaction_screen.dart';
import 'wallet_withdrawal_flow.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const Color _yellow = CitiRideTheme.primaryYellow;

  double balance = WalletBalance.balance;

  Future<void> _refreshBalance() async {
    setState(() {
      balance = WalletBalance.balance;
    });
  }

  void _openTransactionDetails(WalletTransaction transaction) {
    Navigator.pushNamed(
      context,
      '/transaction-details',
      arguments: {
        'title': transaction.title,
        'amount': transaction.amount,
        'isCredit': transaction.isCredit,
        'name': transaction.isCredit ? 'Umoru Osigbemhe' : 'Ahmed Singer',
        'date': 'Fri, 21 Jun 2025',
        'time': '2:30 PM',
        'accountNumber': transaction.accountNumber,
        'bank': transaction.bank,
      },
    );
  }

  Future<void> _openWithdrawalFlow() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletWithdrawalFlow()),
    );
    if (!mounted) return;
    await _refreshBalance();
  }

  void _showAddMoneySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final colors = sheetContext.citiRideColors;

        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D5D5D),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Center(
                child: ProfileAvatar(
                  size: 56,
                  borderColor: colors.border,
                  borderWidth: 1,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Ahmed Singer',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _WalletDetailCopyRow(
                label: "Recipient's account name",
                value: 'CitiRide - Umoru Osigbemhe',
                copyValue: 'CitiRide - Umoru Osigbemhe',
              ),
              _WalletDetailCopyRow(
                label: 'Account number',
                value: '98291029281',
                copyValue: '98291029281',
              ),
              _WalletDetailCopyRow(
                label: 'Bank',
                value: 'Paystack-Titan',
                copyValue: 'Paystack-Titan',
                showDivider: false,
              ),
              const SizedBox(height: 18),
              _FundingMethodTile(
                icon: Icons.credit_card_rounded,
                title: 'Fund with debit card',
                subtitle: 'Use a saved card instead',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Navigator.pushNamed(context, '/top-up');
                  if (!mounted) return;
                  await _refreshBalance();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final showBack = args?['showBack'] == true;
    final colors = context.citiRideColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _yellow,
          backgroundColor: colors.surfaceAlt,
          onRefresh: _refreshBalance,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _WalletHeader(showBack: showBack)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _WalletBalanceCard(balance: balance),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _WalletAction(
                          imageAsset: 'images/add_money.png',
                          label: 'Add money',
                          onTap: _showAddMoneySheet,
                        ),
                        const SizedBox(width: 34),
                        _WalletAction(
                          imageAsset: 'images/withdraw.png',
                          label: 'Withdraw',
                          onTap: _openWithdrawalFlow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ValueListenableBuilder<List<WalletTransaction>>(
                      valueListenable: WalletBalance.transactions,
                      builder: (context, transactions, _) {
                        return _TransactionsPanel(
                          transactions: transactions,
                          onViewAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TransactionScreen(),
                              ),
                            );
                          },
                          onTapTransaction: _openTransactionDetails,
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: showBack
                  ? IconButton(
                      onPressed: () => Navigator.pop(context),
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
                'Wallet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: WalletNotificationButton(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return WalletBalanceCard(balance: balance);
  }
}

/*
class _UnusedWalletBalanceCardStateShim {
  const _UnusedWalletBalanceCardStateShim();
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 333 / 169,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final horizontal = width * 0.07;

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset('images/modal 1.png', fit: BoxFit.fill),
                ),
                Positioned(
                  top: height * 0.12,
                  left: horizontal,
                  right: horizontal,
                  child: const Text(
                    'Elliot Accra',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  left: horizontal,
                  top: height * 0.45,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5332F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-5, 0),
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA929),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: horizontal,
                  top: height * 0.62,
                  child: const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Color(0xFF9C9CA3),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: horizontal,
                  right: horizontal + 34,
                  top: height * 0.72,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _hidden
                          ? '\u20A6••••••'
                          : '\u20A6${widget.balance.toStringAsFixed(2)}',
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: horizontal,
                  top: height * 0.69,
                  child: InkWell(
                    onTap: () => setState(() => _hidden = !_hidden),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        _hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Color(0xFFD5D5D8),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: horizontal,
                  right: horizontal,
                  bottom: height * 0.08,
                  child: const Row(
                    children: [
                      Text(
                        '**2345',
                        style: TextStyle(
                          color: Color(0xFF8B8B91),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '****4342',
                        style: TextStyle(
                          color: Color(0xFF8B8B91),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

*/
class _WalletAction extends StatelessWidget {
  const _WalletAction({
    required this.imageAsset,
    required this.label,
    required this.onTap,
  });

  final String imageAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(imageAsset, fit: BoxFit.cover),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: colors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsPanel extends StatelessWidget {
  const _TransactionsPanel({
    required this.transactions,
    required this.onViewAll,
    required this.onTapTransaction,
  });

  final List<WalletTransaction> transactions;
  final VoidCallback onViewAll;
  final ValueChanged<WalletTransaction> onTapTransaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: CitiRideTheme.primaryYellow,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FilterChip(label: 'All', selected: true),
              const SizedBox(width: 8),
              const _FilterChip(label: 'Earned'),
              const SizedBox(width: 8),
              const _FilterChip(label: 'Spent'),
            ],
          ),
          const SizedBox(height: 12),
          ...transactions.map(
            (transaction) => _WalletTransactionTile(
              transaction: transaction,
              onTap: () => onTapTransaction(transaction),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? colors.text : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? colors.background : colors.text,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WalletTransactionTile extends StatelessWidget {
  const _WalletTransactionTile({
    required this.transaction,
    required this.onTap,
  });

  final WalletTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: transaction.avatarColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.icon,
                color: Colors.black.withValues(alpha: 0.72),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transaction.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.mutedText, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              transaction.amount,
              style: TextStyle(
                color: transaction.amountColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundingMethodTile extends StatelessWidget {
  const _FundingMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CitiRideTheme.primaryYellow.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: CitiRideTheme.primaryYellow, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.mutedText, fontSize: 11),
                  ),
                ],
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

class _WalletDetailCopyRow extends StatelessWidget {
  const _WalletDetailCopyRow({
    required this.label,
    required this.value,
    required this.copyValue,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final String copyValue;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.border))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.mutedText, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyValue));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(
              Icons.copy_rounded,
              color: CitiRideTheme.primaryYellow,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const Color _bg = Color(0xFF101010);
  static const Color _panelAlt = Color(0xFF242424);
  static const Color _yellow = CitiRideTheme.primaryYellow;
  static const Color _muted = Color(0xFF9B9B9B);

  double balance = WalletBalance.balance;

  final List<_WalletTransaction> _transactions = const [
    _WalletTransaction(
      title: 'Payment to Ahmed',
      subtitle: '2:30 PM - Fri, 21 Jun 2025',
      amount: '-\u20A6435.54',
      amountColor: Color(0xFFFF4343),
      icon: Icons.person_rounded,
      avatarColor: Color(0xFFF3C2CD),
    ),
    _WalletTransaction(
      title: 'Wallet Top Up',
      subtitle: '2:30 PM - Fri, 21 Jun 2025',
      amount: '+\u20A6435.54',
      amountColor: Color(0xFF24D05A),
      icon: Icons.arrow_downward_rounded,
      avatarColor: Color(0xFFD9F5DD),
      isCredit: true,
      accountNumber: '3748594032',
      bank: 'UBA',
    ),
    _WalletTransaction(
      title: 'Transfer to Osi',
      subtitle: '2:30 PM - Fri, 21 Jun 2025',
      amount: '-\u20A6435.54',
      amountColor: Color(0xFFFF4343),
      icon: Icons.arrow_upward_rounded,
      avatarColor: Color(0xFFF3C2CD),
    ),
  ];

  Future<void> _refreshBalance() async {
    setState(() {
      balance = WalletBalance.balance;
    });
  }

  void _copyWalletDetails() {
    Clipboard.setData(const ClipboardData(text: 'Paystack-Titan 98291029281'));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wallet details copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openTransactionDetails(_WalletTransaction transaction) {
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

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(18, 10, 18, bottomInset + 18),
          decoration: BoxDecoration(
            color: _panelAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF333333)),
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
              const Text(
                'Add money',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose how you want to fund your CitiRide wallet.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              _FundingMethodTile(
                icon: Icons.credit_card_rounded,
                title: 'Debit card',
                subtitle: 'Fund instantly with a saved card',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Navigator.pushNamed(context, '/top-up');
                  if (!mounted) return;
                  await _refreshBalance();
                },
              ),
              const SizedBox(height: 10),
              _FundingMethodTile(
                icon: Icons.account_balance_rounded,
                title: 'Bank transfer',
                subtitle: 'Send money to your wallet account',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Navigator.pushNamed(context, '/transfer');
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

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _yellow,
          backgroundColor: _panelAlt,
          onRefresh: _refreshBalance,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _WalletHeader(showBack: showBack)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _WalletBalanceCard(
                      balance: balance,
                      onCopy: _copyWalletDetails,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _WalletAction(
                          icon: Icons.add_rounded,
                          label: 'Add money',
                          onTap: _showAddMoneySheet,
                        ),
                        const SizedBox(width: 34),
                        _WalletAction(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Withdraw',
                          onTap: _openWithdrawalFlow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _TransactionsPanel(
                      transactions: _transactions,
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TransactionScreen(),
                          ),
                        );
                      },
                      onTapTransaction: _openTransactionDetails,
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
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : null,
            ),
            const Expanded(
              child: Text(
                'Wallet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.balance, required this.onCopy});

  final double balance;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      decoration: BoxDecoration(
        color: CitiRideTheme.primaryYellow,
        borderRadius: BorderRadius.circular(13),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -52,
            bottom: -34,
            child: Container(
              width: 172,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(54),
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 25,
            child: Container(
              width: 56,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF34340F),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Balance',
                      style: TextStyle(
                        color: CitiRideTheme.primaryYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '\u20A6${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Paystack-Titan 98291029281',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(Icons.copy_rounded, color: Colors.black, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                color: const Color(0xFF242424),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Icon(icon, color: Colors.white, size: 23),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
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

  final List<_WalletTransaction> transactions;
  final VoidCallback onViewAll;
  final ValueChanged<_WalletTransaction> onTapTransaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    color: Colors.white,
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
          const Row(
            children: [
              _FilterChip(label: 'All', selected: true),
              SizedBox(width: 8),
              _FilterChip(label: 'Earned'),
              SizedBox(width: 8),
              _FilterChip(label: 'Spent'),
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
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Colors.white : const Color(0xFF303030),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
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

  final _WalletTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transaction.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _WalletScreenState._muted,
                      fontSize: 10,
                    ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF333333)),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9B9B9B),
                      fontSize: 11,
                    ),
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

class _WalletTransaction {
  const _WalletTransaction({
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

  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color avatarColor;
  final bool isCredit;
  final String? accountNumber;
  final String? bank;
}

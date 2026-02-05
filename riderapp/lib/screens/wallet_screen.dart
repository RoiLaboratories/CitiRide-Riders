import 'package:flutter/material.dart';
import '../components/balance_card.dart';
import '../components/transaction_tile.dart';
import '../components/wallet_action_button.dart';
import '../screens/transaction_screen.dart';
import 'package:flutter/services.dart';
import '../models/wallet_balance.dart';


class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  double balance = WalletBalance.balance;

  Future<void> _refreshBalance() async {
    setState(() {
      balance = WalletBalance.balance;
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool showBack = args?['showBack'] ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshBalance,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
          
                /// Header
               Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showBack)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
          
                  const Text(
                    'Wallet',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          
                  const Spacer(),
          
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Paystack–Titan 98291029281',
                        style: TextStyle(
                          color: Color(0xFF0A84FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            const ClipboardData(text: '98291029281'),
                          );
          
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 2), 
                          child: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Color(0xFF0A84FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          
                const SizedBox(height: 24),
          
                /// Balance Card
                const BalanceCard(),
          
                const SizedBox(height: 28),
          
                /// Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: WalletActionButton(
                        title: 'Top Up',
                        color: Color(0xFF0A84FF),
                        arrowAsset: 'images/top_up.png',
                        onTap: () {
                          Navigator.pushNamed(context, '/top-up');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WalletActionButton(
                        title: 'Transfer',
                        color: Color(0xFFC800FF),
                        arrowAsset: 'images/transfer.png',
                        onTap: () {
                          Navigator.pushNamed(context, '/transfer');
                        },
                      ),
                    ),
                  ],
                ),
          
                const SizedBox(height: 32),
          
                /// Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => TransactionScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF0A84FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          
                const SizedBox(height: 16),
          
                /// Transactions Preview
                Expanded(
                  child: ListView(
                    children: const [
                      TransactionTile(
                        title: 'Payment to Ahmed',
                        time: '2:30 PM · Fri, 21 Jun 2025',
                        amount: '-₦435.54',
                        amountColor: Colors.red,
                        iconBg: Color(0xFFEFF3F6),
                        icon: Icons.person,
                      ),
                      TransactionTile(
                        title: 'Wallet Top Up',
                        time: '2:30 PM · Fri, 21 Jun 2025',
                        amount: '+₦435.54',
                        amountColor: Colors.green,
                        iconBg: Color(0xFFDFF5E1),
                        icon: Icons.arrow_downward,
                      ),
                      TransactionTile(
                        title: 'Transfer to Osi',
                        time: '2:30 PM · Fri, 21 Jun 2025',
                        amount: '-₦435.54',
                        amountColor: Colors.red,
                        iconBg: Color(0xFFFBE4E2),
                        icon: Icons.arrow_upward,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

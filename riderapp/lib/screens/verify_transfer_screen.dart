import 'dart:async';

import 'package:flutter/material.dart';

import '../models/wallet_balance.dart';
import '../theme/app_theme.dart';

class VerifyingTransactionScreen extends StatefulWidget {
  const VerifyingTransactionScreen({super.key});

  @override
  State<VerifyingTransactionScreen> createState() =>
      _VerifyingTransactionScreenState();
}

class _VerifyingTransactionScreenState extends State<VerifyingTransactionScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF101010);
  static const Color _muted = Color(0xFF9B9B9B);

  late final AnimationController _controller1;
  late final AnimationController _controller2;
  late final AnimationController _controller3;
  bool _success = false;
  bool _balanceUpdated = false;

  Map<String, dynamic> get _args {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) return args;
    if (args is num) return {'amount': args.toDouble(), 'topUp': true};
    return const {'amount': 0.0, 'topUp': true};
  }

  double get _amount => (_args['amount'] as num?)?.toDouble() ?? 0;

  @override
  void initState() {
    super.initState();
    _controller1 = _createController(0);
    _controller2 = _createController(260);
    _controller3 = _createController(520);

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (!_balanceUpdated && _amount > 0) {
        WalletBalance.balance += _amount;
        WalletBalance.addTopUp(_amount);
        _balanceUpdated = true;
      }
      setState(() {
        _success = true;
      });

      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    });
  }

  AnimationController _createController(int delay) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    Timer(Duration(milliseconds: delay), () {
      if (mounted) controller.repeat(reverse: true);
    });

    return controller;
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _success ? _buildSuccess() : _buildVerifying(),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifying() {
    return Column(
      key: const ValueKey('verifying'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(_controller1),
            const SizedBox(width: 8),
            _dot(_controller2),
            const SizedBox(width: 8),
            _dot(_controller3),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Verifying transaction',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please wait while we confirm your payment.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 94,
          height: 94,
          decoration: const BoxDecoration(
            color: Color(0xFF20DC5A),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
        ),
        const SizedBox(height: 24),
        const Text(
          'Top-up successful',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '+\u20A6${_amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: CitiRideTheme.primaryYellow,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _dot(AnimationController controller) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.35,
        end: 1,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
      child: const CircleAvatar(
        radius: 7,
        backgroundColor: CitiRideTheme.primaryYellow,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import '../models/wallet_balance.dart';

class VerifyingTransactionScreen extends StatefulWidget {
  const VerifyingTransactionScreen({super.key});

  @override
  State<VerifyingTransactionScreen> createState() =>
      _VerifyingTransactionScreenState();
}

class _VerifyingTransactionScreenState extends State<VerifyingTransactionScreen> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  bool success = false;
  Map<String, dynamic> get args => ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  double get amount => args['amount'] as double;
  bool get topUp => args['topUp'] as bool;

  @override
  void initState() {
    super.initState();
    _controller1 = _createController(0);
    _controller2 = _createController(300);
    _controller3 = _createController(600);

    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
      success = true;
      WalletBalance.balance += amount;
    });
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    });
  }

  AnimationController _createController(int delay) {
    final controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    Future.delayed(Duration(milliseconds: delay), () {
      controller.repeat(reverse: true);
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
      body: Center(
        child: success
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 15),
                  Text("Top-up successful",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              )
            : Column(
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
                  const Text("Verifying transaction",
                    style: TextStyle(fontSize: 16)),
                ],
              ),
      ),
    );
  }

  Widget _dot(AnimationController controller) {
    return ScaleTransition(
      scale: Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: const CircleAvatar(radius: 8, backgroundColor: Colors.black),
    );
  }
}

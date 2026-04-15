import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wallet_balance.dart';

class RideModal extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onContinue;

  const RideModal({
    super.key,
    required this.scrollController,
    required this.onContinue,
  });

  @override
  ConsumerState<RideModal> createState() => _RideModalState();
}

class _RideModalState extends ConsumerState<RideModal> {
  int selectedRide = 0;
  int selectedPayment = 0;
  bool showAllPayments = false;

  /// ─────────────── PAYMENT HANDLER ───────────────
  void handlePayment() {
    double ridePrice = selectedRide == 0 ? 3500 : 7500;

    switch (selectedPayment) {
      case 0: // Cash
        widget.onContinue();
        break;

      case 1: // Wallet
        if (WalletBalance.balance >= ridePrice) {
          WalletBalance.balance -= ridePrice;
          widget.onContinue();
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Insufficient Balance'),
              content:
                  const Text('You do not have enough funds in your wallet.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        break;

      case 2: // Bank Card
        widget.onContinue();
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a payment method'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 18),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _dragHandle(),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildRideOptions(),
                const SizedBox(height: 28),
                _buildPaymentOptions(),
              ],
            ),
          ),

          _continueButton(),
        ],
      ),
    );
  }

  /// ───────────────── DRAG HANDLE ─────────────────
  Widget _dragHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  /// ───────────────── RIDE OPTIONS ─────────────────
  Widget _buildRideOptions() {
    return Column(
      children: [
        _rideCard(
          index: 0,
          title: "Regular",
          subtitle: "Mid-size Cars",
          time: "11 mins",
          seats: "4",
          price: "₦3,500",
          oldPrice: "₦4,500",
          color: Colors.green,
          image: "images/regular.png",
        ),
        const SizedBox(height: 12),
        _rideCard(
          index: 1,
          title: "VIP",
          subtitle: "Modern Car Models",
          time: "5 mins",
          seats: "2",
          price: "₦7,500",
          oldPrice: "₦9,500",
          color: Colors.purple,
          image: "images/vip.png",
        ),
      ],
    );
  }

  Widget _timeAndSeats({
    required String time,
    required String seats,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '•',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.groups,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          seats,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _rideCard({
    required int index,
    required String title,
    required String subtitle,
    required String time,
    required String seats,
    required String price,
    required String oldPrice,
    required Color color,
    required String image,
  }) {
    final isSelected = selectedRide == index;

    return GestureDetector(
      onTap: () => setState(() => selectedRide = index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Image.asset(image, width: 60, height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _timeAndSeats(
                    time: time,
                    seats: seats,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  oldPrice,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ───────────────── PAYMENT OPTIONS ─────────────────
  Widget _buildPaymentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showAllPayments ? "Payment options" : "Select payment option",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        _paymentRow(
          image: "images/cash.png",
          title: "Cash",
          subtitle: "Pay with cash",
          trailing: showAllPayments
              ? _paymentChoice(0)
              : GestureDetector(
                  onTap: () {
                    setState(() => showAllPayments = true);
                  },
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
        ),

        if (showAllPayments) ...[
          const SizedBox(height: 8),

          _paymentRow(
            image: "images/wallet2.png",
            title: "CitiRide Wallet",
            subtitleWidget: Row(
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    children: [
                      const TextSpan(text: "Bal: "),
                      TextSpan(
                        text:
                            "₦${WalletBalance.balance.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _actionPill(
                  text: "+ Top up wallet",
                  onTap: () {
                    Navigator.pushNamed(context, '/top-up');
                  },
                ),
              ],
            ),
            trailing: _paymentChoice(1),
          ),

          _paymentRow(
            image: "images/card.png",
            title: "Bank Card",
            subtitleWidget: Row(
              children: [
                Text(
                  "5678 •••• 2839",
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(width: 8),
                _actionPill(
                  text: "+ Add card",
                  onTap: () {
                    Navigator.pushNamed(context, '/add-card');
                  },
                ),
              ],
            ),
            trailing: _paymentChoice(2),
          ),
        ],
      ],
    );
  }

  Widget _paymentRow({
    required String image,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Image.asset(image, width: 28, height: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                subtitleWidget ??
                    Text(
                      subtitle ?? "",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _paymentChoice(int index) {
    final isSelected = selectedPayment == index;

    return GestureDetector(
      onTap: () {
        setState(() => selectedPayment = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
            width: 2,
          ),
          color: Colors.white,
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _actionPill({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 144, 211, 242),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _continueButton() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: handlePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              "Continue",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
}

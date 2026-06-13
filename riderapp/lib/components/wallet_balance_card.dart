import 'package:flutter/material.dart';

class WalletBalanceCard extends StatefulWidget {
  const WalletBalanceCard({
    super.key,
    required this.balance,
    this.accountName = 'Elliot Accra',
    this.height,
  });

  final double balance;
  final String accountName;
  final double? height;

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final horizontal = width * 0.07;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'images/modal 1.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
              ),
              Positioned(
                top: height * 0.12,
                left: horizontal,
                right: horizontal,
                child: Text(
                  widget.accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                      color: const Color(0xFFD5D5D8),
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
    );

    if (widget.height != null) {
      return SizedBox(width: double.infinity, height: widget.height, child: card);
    }

    return AspectRatio(aspectRatio: 333 / 169, child: card);
  }
}

class WalletNotificationButton extends StatelessWidget {
  const WalletNotificationButton({super.key, required this.onTap, this.size = 42});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Image.asset(
            isDark ? 'images/bell1.png' : 'images/bell.png',
            width: size * 0.58,
            height: size * 0.58,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),
        ),
      ),
    );
  }
}

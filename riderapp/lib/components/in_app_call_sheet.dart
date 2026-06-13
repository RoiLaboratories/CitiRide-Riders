import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

Future<void> showRideInAppCall(
  BuildContext context, {
  required String driverName,
  required String driverSubtitle,
  String avatarAsset = 'images/driver.png',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Ride call',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: _RideCallCard(
            driverName: driverName,
            driverSubtitle: driverSubtitle,
            avatarAsset: avatarAsset,
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _RideCallCard extends StatefulWidget {
  const _RideCallCard({
    required this.driverName,
    required this.driverSubtitle,
    required this.avatarAsset,
  });

  final String driverName;
  final String driverSubtitle;
  final String avatarAsset;

  @override
  State<_RideCallCard> createState() => _RideCallCardState();
}

class _RideCallCardState extends State<_RideCallCard> {
  Timer? _connectTimer;
  Timer? _durationTimer;
  Duration _duration = Duration.zero;
  bool _connected = false;
  bool _muted = false;
  bool _speakerOn = true;

  @override
  void initState() {
    super.initState();
    _connectTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _connected = true);
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _duration += const Duration(seconds: 1));
      });
    });
  }

  @override
  void dispose() {
    _connectTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  String get _statusText {
    if (!_connected) return 'Calling...';
    final minutes = _duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _endCall() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.sizeOf(context).width.clamp(0, 420).toDouble() - 32,
        constraints: const BoxConstraints(maxWidth: 390),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.36),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.asset(
                widget.avatarAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.driverName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.driverSubtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _statusText,
              style: TextStyle(
                color: _connected
                    ? CitiRideTheme.primaryYellow
                    : colors.mutedText,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallControlButton(
                  icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: _muted ? 'Muted' : 'Mute',
                  active: _muted,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _muted = !_muted);
                  },
                ),
                _CallControlButton(
                  icon: _speakerOn
                      ? Icons.volume_up_rounded
                      : Icons.hearing_rounded,
                  label: 'Speaker',
                  active: _speakerOn,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _speakerOn = !_speakerOn);
                  },
                ),
                _CallControlButton(
                  icon: Icons.call_end_rounded,
                  label: 'End',
                  danger: true,
                  onTap: _endCall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;
    final fill = danger
        ? const Color(0xFFFF3B3B)
        : active
        ? CitiRideTheme.primaryYellow
        : colors.surface;
    final iconColor = danger || active ? Colors.black : colors.text;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: danger ? const Color(0xFFFF7070) : colors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

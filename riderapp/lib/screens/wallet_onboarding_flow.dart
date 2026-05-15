import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class WalletOnboardingFlow extends StatefulWidget {
  const WalletOnboardingFlow({super.key});

  @override
  State<WalletOnboardingFlow> createState() => _WalletOnboardingFlowState();
}

class _WalletOnboardingFlowState extends State<WalletOnboardingFlow> {
  static const Color _bg = Color(0xFF101010);
  static const Color _panelAlt = Color(0xFF232323);
  static const Color _yellow = CitiRideTheme.primaryYellow;
  static const Color _muted = Color(0xFF9B9B9B);

  final TextEditingController _identityController = TextEditingController();

  int _step = 0;
  String _documentType = 'Bank Verification Number (BVN)';
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmingPin = false;
  bool _isSaving = false;
  String? _pinError;

  final List<String> _documents = const [
    'Bank Verification Number (BVN)',
    'National Identification Number (NIN)',
    'International passport',
  ];

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  double get _progress {
    switch (_step) {
      case 0:
        return 0.18;
      case 1:
        return 0.34;
      case 2:
        return 0.52;
      case 3:
        return 0.70;
      case 4:
        return 0.86;
      default:
        return 1;
    }
  }

  String get _title {
    switch (_step) {
      case 0:
        return 'Citi Wallet';
      case 1:
        return 'Wallet';
      case 2:
      case 3:
        return 'Verify your ID';
      case 4:
        return _isConfirmingPin ? 'Confirm passcode' : 'Create passcode';
      default:
        return '';
    }
  }

  bool get _canContinue {
    if (_isSaving) return false;

    switch (_step) {
      case 3:
        return _identityController.text.trim().length >= 5;
      case 4:
        return (_isConfirmingPin ? _confirmPin : _pin).length == 6;
      default:
        return true;
    }
  }

  Future<void> _finish() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wallet_onboarding_complete', true);
      await prefs.setString('wallet_account_name', 'CitiRide Wallet');
      await prefs.setString('wallet_account_bank', 'Paystack-Titan');
      await prefs.setString('wallet_account_number', '98291029281');
      await prefs.setString('wallet_pin', _pin);
      await prefs.setString(
        'wallet_pin_last_updated',
        DateTime.now().toIso8601String(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _next() {
    if (!_canContinue) return;

    if (_step == 4) {
      if (!_isConfirmingPin) {
        setState(() {
          _isConfirmingPin = true;
          _confirmPin = '';
          _pinError = null;
        });
        return;
      }

      if (_pin != _confirmPin) {
        setState(() {
          _confirmPin = '';
          _pinError = 'Passcodes do not match. Try again.';
        });
        return;
      }

      setState(() {
        _step = 5;
      });
      return;
    }

    setState(() {
      _step += 1;
    });
  }

  void _skipIdentity() {
    setState(() {
      _step = 4;
      _pinError = null;
    });
  }

  void _back() {
    if (_step == 5) return;

    if (_step == 4 && _isConfirmingPin) {
      setState(() {
        _isConfirmingPin = false;
        _confirmPin = '';
        _pinError = null;
      });
      return;
    }

    if (_step > 0) {
      setState(() {
        _step -= 1;
      });
      return;
    }

    Navigator.of(context).pop(false);
  }

  void _onPinDigit(String digit) {
    final current = _isConfirmingPin ? _confirmPin : _pin;
    if (current.length >= 6) return;

    setState(() {
      if (_isConfirmingPin) {
        _confirmPin += digit;
      } else {
        _pin += digit;
      }
      _pinError = null;
    });
  }

  void _onPinDelete() {
    final current = _isConfirmingPin ? _confirmPin : _pin;
    if (current.isEmpty) return;

    setState(() {
      if (_isConfirmingPin) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else {
        _pin = _pin.substring(0, _pin.length - 1);
      }
      _pinError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _FlowHeader(
                title: _title,
                canBack: _step != 5,
                showSkip: _step == 2 || _step == 3,
                onBack: _back,
                onSkip: _skipIdentity,
              ),
              if (_step != 5)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 2, 24, 0),
                  child: _ProgressStrip(progress: _progress),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey('wallet_step_${_step}_$_isConfirmingPin'),
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
        return _buildWelcomeStep();
      case 1:
        return _buildRequirementsStep();
      case 2:
        return _buildDocumentStep();
      case 3:
        return _buildIdentityNumberStep();
      case 4:
        return _buildPinStep();
      default:
        return _buildSuccessStep();
    }
  }

  Widget _screenPadding({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeStep() {
    return _screenPadding(
      child: Column(
        children: [
          const SizedBox(height: 10),
          const _WalletHeroGraphic(),
          const SizedBox(height: 34),
          const Text(
            'CitiRide Wallet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pay for rides, receive refunds, top up and withdraw from one secure balance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 30),
          _WalletNotice(
            icon: Icons.lock_rounded,
            title: 'Protected by your passcode',
            subtitle: 'You will set a 6-digit wallet passcode in this flow.',
          ),
          const Spacer(),
          _PrimaryWalletButton(label: 'Agree', onPressed: _next),
        ],
      ),
    );
  }

  Widget _buildRequirementsStep() {
    return _screenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Before you get started',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We only need a few details to keep your wallet compliant and safe.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          const _RequirementTile(
            icon: Icons.badge_outlined,
            title: 'Government issued ID',
            subtitle: 'BVN, NIN or passport details for verification.',
          ),
          const SizedBox(height: 12),
          const _RequirementTile(
            icon: Icons.home_work_outlined,
            title: 'Home address',
            subtitle: 'Your account address keeps transfers protected.',
          ),
          const SizedBox(height: 12),
          const _RequirementTile(
            icon: Icons.password_rounded,
            title: 'Wallet passcode',
            subtitle: 'A private 6-digit code for wallet actions.',
          ),
          const Spacer(),
          _PrimaryWalletButton(label: "Let's go", onPressed: _next),
        ],
      ),
    );
  }

  Widget _buildDocumentStep() {
    return _screenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Verify your government ID',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the document you want to use for wallet verification.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          ..._documents.map(
            (document) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DocumentChoice(
                title: document,
                selected: _documentType == document,
                onTap: () {
                  setState(() {
                    _documentType = document;
                    _identityController.clear();
                  });
                },
              ),
            ),
          ),
          const Spacer(),
          _PrimaryWalletButton(label: 'Next', onPressed: _next),
        ],
      ),
    );
  }

  Widget _buildIdentityNumberStep() {
    final hint = _documentType.contains('BVN')
        ? 'Enter your BVN'
        : _documentType.contains('NIN')
        ? 'Enter your NIN'
        : 'Enter passport number';
    final keyboardType = _documentType.contains('passport')
        ? TextInputType.text
        : TextInputType.number;
    final inputFormatters = _documentType.contains('passport')
        ? <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ]
        : <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly];

    return _screenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Verify your government ID',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _documentType,
            style: const TextStyle(
              color: _yellow,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: _panelAlt,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _identityController.text.trim().isEmpty
                    ? const Color(0xFF2D2D2D)
                    : _yellow,
              ),
            ),
            child: TextField(
              controller: _identityController,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: _yellow,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _muted, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _WalletNotice(
            icon: Icons.verified_user_outlined,
            title: 'Your details stay encrypted',
            subtitle:
                'CitiRide only uses this to create and protect your wallet.',
          ),
          const Spacer(),
          _PrimaryWalletButton(
            label: 'Next',
            onPressed: _canContinue ? _next : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    final value = _isConfirmingPin ? _confirmPin : _pin;
    final subtitle = _isConfirmingPin
        ? 'Re-enter your 6-digit passcode'
        : 'Set a 6-digit passcode for wallet transactions';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          _PasscodeBoxes(value: value, error: _pinError != null),
          if (_pinError != null) ...[
            const SizedBox(height: 10),
            Text(
              _pinError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF4343),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          _WalletKeypad(
            onDigitPressed: _onPinDigit,
            onDeletePressed: _onPinDelete,
          ),
          const SizedBox(height: 22),
          _PrimaryWalletButton(
            label: _isConfirmingPin ? 'Create wallet' : 'Next',
            loading: _isSaving,
            onPressed: _canContinue ? _next : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: Color(0xFF20DC5A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 58,
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Wallet created successfully',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your CitiRide wallet is ready to use.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const Spacer(),
          _PrimaryWalletButton(
            label: 'Proceed to wallet',
            loading: _isSaving,
            onPressed: _finish,
          ),
        ],
      ),
    );
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    required this.canBack,
    required this.showSkip,
    required this.onBack,
    required this.onSkip,
  });

  final String title;
  final bool canBack;
  final bool showSkip;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: canBack
                  ? IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 64,
              child: showSkip
                  ? TextButton(
                      onPressed: onSkip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: CitiRideTheme.primaryYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 3,
        color: const Color(0xFF242424),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(color: CitiRideTheme.primaryYellow),
        ),
      ),
    );
  }
}

class _WalletHeroGraphic extends StatelessWidget {
  const _WalletHeroGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 182,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 18,
            left: 34,
            right: 34,
            child: Transform.rotate(
              angle: -math.pi / 18,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: CitiRideTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 18,
            right: 18,
            child: Transform.rotate(
              angle: -math.pi / 28,
              child: Container(
                height: 74,
                decoration: BoxDecoration(
                  color: CitiRideTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 18),
                    child: Text(
                      'CitiRide',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFF2B2B2B)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -26,
                    bottom: -18,
                    child: Container(
                      width: 130,
                      height: 78,
                      decoration: BoxDecoration(
                        color: CitiRideTheme.primaryYellow.withValues(
                          alpha: 0.28,
                        ),
                        borderRadius: BorderRadius.circular(44),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    top: 16,
                    child: Text(
                      'Wallet balance',
                      style: TextStyle(
                        color: Color(0xFFB9B9B9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    top: 38,
                    child: Text(
                      '\u20A60.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    bottom: 14,
                    child: Text(
                      'Paystack-Titan 98291029281',
                      style: TextStyle(color: Color(0xFF777777), fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF2D2D2D)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: CitiRideTheme.primaryYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, color: CitiRideTheme.primaryYellow, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9B9B9B),
                    fontSize: 11,
                    height: 1.35,
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

class _DocumentChoice extends StatelessWidget {
  const _DocumentChoice({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF22220F) : const Color(0xFF181818),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected
                ? CitiRideTheme.primaryYellow
                : const Color(0xFF2D2D2D),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? CitiRideTheme.primaryYellow
                      : const Color(0xFF646464),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: CitiRideTheme.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletNotice extends StatelessWidget {
  const _WalletNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: CitiRideTheme.primaryYellow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9B9B9B),
                    fontSize: 11,
                    height: 1.35,
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

class _PasscodeBoxes extends StatelessWidget {
  const _PasscodeBoxes({required this.value, required this.error});

  final String value;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final isFilled = index < value.length;
        final isFocused = index == value.length && value.length < 6;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF232323),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: error
                  ? const Color(0xFFFF4343)
                  : isFocused
                  ? CitiRideTheme.primaryYellow
                  : const Color(0xFF303030),
            ),
          ),
          child: isFilled
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        );
      }),
    );
  }
}

class _WalletKeypad extends StatelessWidget {
  const _WalletKeypad({
    required this.onDigitPressed,
    required this.onDeletePressed,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(['1', '2', '3']),
        const SizedBox(height: 18),
        _row(['4', '5', '6']),
        const SizedBox(height: 18),
        _row(['7', '8', '9']),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 66, height: 44),
            _KeypadButton(label: '0', onTap: () => onDigitPressed('0')),
            SizedBox(
              width: 66,
              height: 44,
              child: IconButton(
                onPressed: onDeletePressed,
                icon: const Icon(
                  Icons.backspace_outlined,
                  color: Color(0xFFBDBDBD),
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (digit) =>
                _KeypadButton(label: digit, onTap: () => onDigitPressed(digit)),
          )
          .toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: SizedBox(
        width: 66,
        height: 44,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFEFEFEF),
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryWalletButton extends StatelessWidget {
  const _PrimaryWalletButton({
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
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

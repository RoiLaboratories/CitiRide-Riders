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

  final TextEditingController _phoneController = TextEditingController(
    text: '907 010 7455',
  );
  final TextEditingController _phoneOtpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  int _step = 0;
  String _pin = '';
  String _confirmPin = '';
  bool _ageConsent = false;
  bool _termsConsent = false;
  bool _privacyConsent = false;
  bool _isConfirmingPin = false;
  bool _isSaving = false;
  String? _pinError;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneOtpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  double get _progress {
    switch (_step) {
      case 0:
        return 0.12;
      case 1:
        return 0.24;
      case 2:
        return 0.38;
      case 3:
        return 0.52;
      case 4:
        return 0.66;
      case 5:
        return 0.78;
      case 6:
        return 0.90;
      default:
        return 1;
    }
  }

  String get _title {
    switch (_step) {
      case 0:
        return 'Wallet';
      case 1:
        return 'Wallet';
      case 2:
        return 'Wallet';
      case 3:
        return 'CitiRide Wallet';
      case 4:
        return 'Verify your phone number';
      case 5:
        return 'Wallet';
      case 6:
        return _isConfirmingPin ? 'Confirm passcode' : 'Create passcode';
      default:
        return '';
    }
  }

  bool get _canContinue {
    if (_isSaving) return false;

    switch (_step) {
      case 2:
        return _phoneController.text.replaceAll(RegExp(r'\D'), '').length >= 8;
      case 3:
        return _ageConsent && _termsConsent && _privacyConsent;
      case 4:
        return _phoneOtpController.text.length == 6;
      case 5:
        return RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
        ).hasMatch(_emailController.text.trim());
      case 6:
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
      await prefs.setString('wallet_phone', '+234${_phoneController.text}');
      await prefs.setString('wallet_email', _emailController.text.trim());
      if ((prefs.getString('profile_email') ?? '').trim().isEmpty) {
        await prefs.setString('profile_email', _emailController.text.trim());
      }
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

    if (_step == 6) {
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
        _step = 7;
      });
      return;
    }

    setState(() {
      _step += 1;
    });
  }

  void _skipIdentity() {
    setState(() {
      _step = 6;
      _pinError = null;
    });
  }

  void _back() {
    if (_step == 7) return;

    if (_step == 6 && _isConfirmingPin) {
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

  void _onOtpDigit(String digit) {
    if (_phoneOtpController.text.length >= 6) return;
    setState(() {
      _phoneOtpController.text += digit;
    });
  }

  void _onOtpDelete() {
    final value = _phoneOtpController.text;
    if (value.isEmpty) return;
    setState(() {
      _phoneOtpController.text = value.substring(0, value.length - 1);
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
                canBack: _step != 7,
                showSkip: false,
                onBack: _back,
                onSkip: _skipIdentity,
              ),
              if (_step != 7)
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
        return _buildPhoneStep();
      case 3:
        return _buildConsentStep();
      case 4:
        return _buildPhoneVerificationStep();
      case 5:
        return _buildEmailStep();
      case 6:
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
            'Confirm these requirements so your wallet can be created securely.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          const _RequirementTile(
            icon: Icons.cake_outlined,
            title: 'You are 18 years and older',
            subtitle: 'CitiRide wallet is available to eligible adults.',
          ),
          const SizedBox(height: 12),
          const _RequirementTile(
            icon: Icons.badge_outlined,
            title: 'You have a valid ID',
            subtitle: 'Keep a government ID ready for account checks.',
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

  Widget _buildPhoneStep() {
    return _screenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            "What's your phone number?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the phone number you want to use for wallet security.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: _panelAlt,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _yellow),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D5F2A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'NG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '+234',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: _yellow,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Phone number',
                      hintStyle: TextStyle(color: _muted, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _muted,
                  size: 22,
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _WalletNotice(
            icon: Icons.info_outline_rounded,
            title: 'SMS verification',
            subtitle: 'A one-time code will be sent to this phone number.',
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

  Widget _buildConsentStep() {
    return _screenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'CitiRide needs your consent to continue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _ConsentTile(
            selected: _ageConsent,
            title: 'I am 18 years old and above',
            subtitle: 'Your wallet account requires age confirmation.',
            onTap: () => setState(() => _ageConsent = !_ageConsent),
          ),
          const SizedBox(height: 12),
          _ConsentTile(
            selected: _termsConsent,
            title: 'I have read and agree to the Terms',
            subtitle: 'This covers wallet access, transfers and fees.',
            onTap: () => setState(() => _termsConsent = !_termsConsent),
          ),
          const SizedBox(height: 12),
          _ConsentTile(
            selected: _privacyConsent,
            title: 'I consent to wallet verification checks',
            subtitle: 'CitiRide may verify submitted details securely.',
            onTap: () => setState(() => _privacyConsent = !_privacyConsent),
          ),
          const Spacer(),
          _PrimaryWalletButton(
            label: 'Continue',
            onPressed: _canContinue ? _next : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneVerificationStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'Enter the 6-digit code sent to your phone number',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          _CodeBoxes(value: _phoneOtpController.text),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Text(
              "Didn't get the code?",
              style: TextStyle(
                color: _yellow,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          _WalletKeypad(
            onDigitPressed: _onOtpDigit,
            onDeletePressed: _onOtpDelete,
          ),
          const SizedBox(height: 22),
          _PrimaryWalletButton(
            label: 'Next',
            onPressed: _canContinue ? _next : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return _screenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            "What's your email address",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the email address that should receive wallet updates.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: _panelAlt,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _emailController.text.trim().isEmpty
                    ? const Color(0xFF2D2D2D)
                    : _yellow,
              ),
            ),
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: _yellow,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Email address',
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
            icon: Icons.mark_email_read_outlined,
            title: 'Email alerts',
            subtitle:
                'Statements, transfer updates and security alerts can be sent here.',
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
      child: Image.asset('images/modal.png', fit: BoxFit.contain),
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

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9B9B9B),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
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

class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final digit = index < value.length ? value[index] : '';
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
              color: isFocused
                  ? CitiRideTheme.primaryYellow
                  : const Color(0xFF303030),
            ),
          ),
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }),
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

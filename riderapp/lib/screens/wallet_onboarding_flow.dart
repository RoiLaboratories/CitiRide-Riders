import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class WalletOnboardingFlow extends StatefulWidget {
  const WalletOnboardingFlow({super.key, this.openWalletOnFinish = false});

  final bool openWalletOnFinish;

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
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _transactionPinController =
      TextEditingController();
  final TextEditingController _confirmTransactionPinController =
      TextEditingController();

  int _step = 0;
  String _pin = '';
  String _confirmPin = '';
  String _transactionPin = '';
  String _confirmTransactionPin = '';
  bool _termsConsent = false;
  bool _privacyConsent = false;
  bool _marketingConsent = false;
  bool _isConfirmingPin = false;
  bool _isSaving = false;
  String? _pinError;
  String? _ninError;
  String? _transactionPinError;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneOtpController.dispose();
    _emailController.dispose();
    _ninController.dispose();
    _transactionPinController.dispose();
    _confirmTransactionPinController.dispose();
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
      case 7:
        return 0.92;
      case 8:
        return 0.95;
      case 9:
        return 0.98;
      default:
        return 1;
    }
  }

  bool get _canContinue {
    if (_isSaving) return false;

    switch (_step) {
      case 2:
        return _phoneController.text.replaceAll(RegExp(r'\D'), '').length >= 8;
      case 3:
        return _termsConsent && _privacyConsent;
      case 4:
        return _phoneOtpController.text.length == 6;
      case 5:
        return RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
        ).hasMatch(_emailController.text.trim());
      case 6:
        return (_isConfirmingPin ? _confirmPin : _pin).length == 6;
      case 7:
        return true;
      case 8:
        return _ninController.text.trim().isNotEmpty;
      case 9:
        return _transactionPin.length == 6 &&
            _confirmTransactionPin.length == 6;
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
      await prefs.setString('wallet_transaction_pin', _transactionPin);
      await prefs.setString('wallet_nin', _ninController.text.trim());
      await prefs.setBool('wallet_marketing_consent', _marketingConsent);
      await prefs.setString(
        'wallet_pin_last_updated',
        DateTime.now().toIso8601String(),
      );

      if (!mounted) return;
      if (widget.openWalletOnFinish) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
          arguments: {'initialTabIndex': 2},
        );
      } else {
        Navigator.of(context).pop(true);
      }
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

    if (_step == 8 && _ninController.text.trim().isEmpty) {
      setState(() => _ninError = 'NIN is required');
      return;
    }

    if (_step == 9) {
      if (_transactionPin != _confirmTransactionPin) {
        setState(() => _transactionPinError = 'Retry code');
        return;
      }
      setState(() => _step = 10);
      return;
    }

    setState(() {
      _step += 1;
    });
  }

  void _skipEmail() {
    setState(() {
      _emailController.clear();
      _step = 6;
    });
  }

  void _back() {
    if (_step == 10) return;

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
                title: '',
                canBack: _step != 10,
                showNeedHelp: _step >= 3 && _step <= 8,
                showPhoneChip: _step == 6,
                onBack: _back,
              ),
              if (_step < 6)
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
      case 7:
        return _buildIdentityOptionStep();
      case 8:
        return _buildNinStep();
      case 9:
        return _buildTransactionPinStep();
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
          const SizedBox(height: 54),
          const Text(
            'CitiRide needs your consent to continue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 76),
          _ConsentCheckboxLine(
            selected: _termsConsent,
            onTap: () => setState(() => _termsConsent = !_termsConsent),
            spans: const [
              TextSpan(text: 'I have read and agree to the '),
              TextSpan(
                text: 'Terms and\nConditions',
                style: TextStyle(color: Color(0xFF0B7CFF)),
              ),
              TextSpan(text: ' and '),
              TextSpan(
                text: 'Data privacy statement',
                style: TextStyle(color: Color(0xFF0B7CFF)),
              ),
            ],
          ),
          const SizedBox(height: 36),
          _ConsentCheckboxLine(
            selected: _privacyConsent,
            onTap: () => setState(() => _privacyConsent = !_privacyConsent),
            spans: const [
              TextSpan(text: 'I have read and agree to the '),
              TextSpan(
                text: 'Data\nprocessing consent',
                style: TextStyle(color: Color(0xFF0B7CFF)),
              ),
            ],
          ),
          const SizedBox(height: 36),
          _ConsentCheckboxLine(
            selected: _marketingConsent,
            onTap: () => setState(() => _marketingConsent = !_marketingConsent),
            spans: const [
              TextSpan(
                text:
                    'I would like to receive marketing and\n'
                    'promotional information ',
              ),
              TextSpan(
                text: '(optional)',
                style: TextStyle(color: Color(0xFF9B9B9B)),
              ),
            ],
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
    return _screenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 54),
          const Text(
            'Verify Your Phone Number',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "We've sent a 6 digit code to *** 2057. Check your SMS\n"
            'and enter it here.',
            style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 82),
          _EditableCodeBoxes(
            controller: _phoneOtpController,
            value: _phoneOtpController.text,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _yellow, size: 23),
              const SizedBox(width: 16),
              const Text(
                "Didn't get the code?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Resend',
                  style: TextStyle(
                    color: _yellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
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

  Widget _buildEmailStep() {
    return _screenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 54),
          const Text(
            "What's Your Email Address",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter the email you want associated with this account',
            style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 108),
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: _panelAlt,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFF303030)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 28),
                const Icon(Icons.email_rounded, color: _muted, size: 23),
                const SizedBox(width: 28),
                Expanded(
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
                    decoration: const InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: TextStyle(
                        color: _muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
              ],
            ),
          ),
          const SizedBox(height: 56),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: _yellow, size: 23),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "A verification link will be sent to this email, make sure it's\n"
                  'correct before you continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _PrimaryWalletButton(
            label: 'Next',
            onPressed: _canContinue ? _next : null,
          ),
          const SizedBox(height: 16),
          _SecondaryWalletButton(
            label: "I don't have an email",
            onPressed: _skipEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    final value = _isConfirmingPin ? _confirmPin : _pin;
    final title = _isConfirmingPin
        ? 'Confirm passcode'
        : 'Set up your passcode';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Enter a 6 digit passcode',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 72),
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
            onSubmit: _next,
            submitEnabled: _canContinue,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityOptionStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Select an option',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Select the type of ID to validate',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 34),
          _IdentityOptionTile(
            icon: Icons.description_outlined,
            title: 'National Identification Number (NIN)',
            subtitle: "Don't have NIN? Dial *346# on your registered number.",
            onTap: () => setState(() => _step = 8),
          ),
          const SizedBox(height: 30),
          _IdentityOptionTile(
            icon: Icons.account_balance_outlined,
            title: 'Bank Verification Number (BVN)',
            subtitle: "Don't have BVN? Dial *565*0# on your registered number.",
            onTap: () => setState(() => _step = 8),
          ),
          const SizedBox(height: 26),
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: CitiRideTheme.primaryYellow,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'You can proceed with either one',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNinStep() {
    return _screenPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Verify your NIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Select the type of ID to validate',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 38),
          TextField(
            controller: _ninController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _ninError = null),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'National Identification Number',
              hintStyle: const TextStyle(color: _muted, fontSize: 13),
              filled: true,
              fillColor: _panelAlt,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(
                  color: _ninError == null
                      ? const Color(0xFF303030)
                      : const Color(0xFFFF3434),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(
                  color: _ninError == null
                      ? const Color(0xFF303030)
                      : const Color(0xFFFF3434),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(
                  color: _ninError == null
                      ? CitiRideTheme.primaryYellow
                      : const Color(0xFFFF3434),
                ),
              ),
            ),
          ),
          if (_ninError != null) ...[
            const SizedBox(height: 8),
            Text(
              _ninError!,
              style: const TextStyle(
                color: Color(0xFFFF3434),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: CitiRideTheme.primaryYellow,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Dial ',
                    children: [
                      TextSpan(
                        text: '*346#',
                        style: TextStyle(color: Color(0xFF0B7CFF)),
                      ),
                      TextSpan(
                        text:
                            ' on your registered phone number to get your NIN. Service costs ₦20. Or visit ',
                      ),
                      TextSpan(
                        text: 'nimc.gov.ng/sms-service',
                        style: TextStyle(color: Color(0xFF0B7CFF)),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _PrimaryWalletButton(
            label: 'Next',
            onPressed: _canContinue
                ? _next
                : () {
                    setState(() => _ninError = 'NIN is required');
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionPinStep() {
    final hasError = _transactionPinError != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Set Up Your Transaction Pin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Choose your transaction pin',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 52),
          const Text(
            'Enter transaction pin',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _EditablePasscodeBoxes(
            controller: _transactionPinController,
            value: _transactionPin,
            error: false,
            onChanged: (value) {
              setState(() {
                _transactionPin = value;
                _transactionPinError = null;
              });
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Confirm transaction pin',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _EditablePasscodeBoxes(
            controller: _confirmTransactionPinController,
            value: _confirmTransactionPin,
            error: hasError,
            onChanged: (value) {
              setState(() {
                _confirmTransactionPin = value;
                _transactionPinError = null;
              });
            },
          ),
          if (hasError) ...[
            const SizedBox(height: 14),
            Text(
              _transactionPinError!,
              style: const TextStyle(
                color: Color(0xFFFF3434),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const Spacer(),
          _PrimaryWalletButton(label: 'Create Pin', onPressed: _next),
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

class _IdentityOptionTile extends StatelessWidget {
  const _IdentityOptionTile({
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
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8E8E8E),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right_rounded,
            color: CitiRideTheme.primaryYellow,
            size: 26,
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
    required this.showNeedHelp,
    required this.showPhoneChip,
    required this.onBack,
  });

  final String title;
  final bool canBack;
  final bool showNeedHelp;
  final bool showPhoneChip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              width: 104,
              child: Align(
                alignment: Alignment.centerRight,
                child: showPhoneChip
                    ? Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F2E0D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              color: CitiRideTheme.primaryYellow,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '***2057',
                              style: TextStyle(
                                color: CitiRideTheme.primaryYellow,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      )
                    : showNeedHelp
                    ? TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Need Help?',
                          maxLines: 1,
                          style: TextStyle(
                            color: CitiRideTheme.primaryYellow,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryWalletButton extends StatelessWidget {
  const _SecondaryWalletButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CitiRideTheme.primaryYellow,
          side: const BorderSide(
            color: CitiRideTheme.primaryYellow,
            width: 1.6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: CitiRideTheme.primaryYellow,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ConsentCheckboxLine extends StatelessWidget {
  const _ConsentCheckboxLine({
    required this.selected,
    required this.onTap,
    required this.spans,
  });

  final bool selected;
  final VoidCallback onTap;
  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 1.4),
              color: selected
                  ? CitiRideTheme.primaryYellow
                  : Colors.transparent,
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text.rich(
              TextSpan(children: spans),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
      height: 250,
      child: Transform.scale(
        scale: 1.08,
        child: Image.asset('images/modal.png', fit: BoxFit.contain),
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
          width: 48,
          height: 48,
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

class _EditableCodeBoxes extends StatelessWidget {
  const _EditableCodeBoxes({
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _CodeBoxes(value: value),
        Positioned.fill(
          child: Opacity(
            opacity: 0.01,
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ),
      ],
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
          width: 48,
          height: 48,
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

class _EditablePasscodeBoxes extends StatelessWidget {
  const _EditablePasscodeBoxes({
    required this.controller,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String value;
  final bool error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _PasscodeBoxes(value: value, error: error),
        Positioned.fill(
          child: Opacity(
            opacity: 0.01,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletKeypad extends StatelessWidget {
  const _WalletKeypad({
    required this.onDigitPressed,
    required this.onDeletePressed,
    required this.onSubmit,
    required this.submitEnabled,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onSubmit;
  final bool submitEnabled;

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
            SizedBox(
              width: 66,
              height: 52,
              child: IconButton(
                onPressed: onDeletePressed,
                icon: const Icon(
                  Icons.backspace_rounded,
                  color: Color(0xFFBDBDBD),
                  size: 24,
                ),
              ),
            ),
            _KeypadButton(label: '0', onTap: () => onDigitPressed('0')),
            SizedBox(
              width: 66,
              height: 52,
              child: Center(
                child: InkResponse(
                  onTap: submitEnabled ? onSubmit : null,
                  radius: 36,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: submitEnabled
                          ? CitiRideTheme.primaryYellow
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: submitEnabled
                          ? Colors.black
                          : const Color(0xFF9B9B9B),
                      size: 28,
                    ),
                  ),
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

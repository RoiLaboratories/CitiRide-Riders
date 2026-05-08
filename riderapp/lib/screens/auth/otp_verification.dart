import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/auth_components.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final ConfirmationResult? webConfirmationResult;
  final String verificationId;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.webConfirmationResult,
  });

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  static const int otpLength = 6;

  int _resendTimer = 60;
  Timer? _timer;
  bool _isOtpVerified = false;
  bool _isVerifying = false;
  String _errorMessage = '';

  final List<String> _enteredDigits = [];
  int _currentFocusIndex = 0; // Track which field should be "focused"

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _currentFocusIndex = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------- TIMER ----------------
  void _startResendTimer() {
    _timer?.cancel();
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  // ---------------- OTP HANDLING ----------------
  String get _otp => _enteredDigits.join();

  void _onOtpCircleTapped(int index) {
    setState(() {
      _currentFocusIndex = index < _enteredDigits.length
          ? index
          : _enteredDigits.length;
      if (_currentFocusIndex >= otpLength) _currentFocusIndex = -1;
      _errorMessage = '';
    });
  }

  // ---------------- KEYPAD ----------------
  void _onDigitPressed(String digit) {
    if (_enteredDigits.length < otpLength) {
      setState(() {
        _enteredDigits.add(digit);
        _errorMessage = '';
        _currentFocusIndex = _enteredDigits.length;
        if (_currentFocusIndex >= otpLength) _currentFocusIndex = -1;
        _isOtpVerified = _enteredDigits.length == otpLength;
      });
    }
  }

  void _onClearPressed() {
    if (_enteredDigits.isNotEmpty) {
      setState(() {
        _enteredDigits.removeLast();
        _errorMessage = '';
        _currentFocusIndex = _enteredDigits.length;
        _isOtpVerified = false;
      });
    }
  }

  // ---------------- ACTIONS ----------------
  void _resendOTP() {
    setState(() {
      _enteredDigits.clear();
      _errorMessage = '';
      _currentFocusIndex = 0;
      _isOtpVerified = false;
    });

    _startResendTimer();

    // Show custom snackbar from top
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'OTP resent to ${widget.phoneNumber}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove snackbar after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _onVerifyPressed() async {
    if (!_isOtpVerified || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      ref.read(authProvider);

      setState(() {
        _currentFocusIndex = -1;
        _isOtpVerified = true;
      });

      // Show success overlay/snackbar
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'OTP verified successfully!',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
      overlay.insert(overlayEntry);

      // Remove overlay after 2 seconds
      Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());

      // Navigate to home screen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      });
    } on FirebaseAuthException {
      // Handle Firebase-specific errors
      _showOtpError();
    } catch (e) {
      // Handle generic errors
      _showOtpError();
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _showOtpError() {
    setState(() {
      _currentFocusIndex = -1;
      _isOtpVerified = false;
      _errorMessage = 'Incorrect code';
    });

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Invalid OTP. Please try again.',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        centerTitle: true,
        title: Text(
          "Enter the code",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'A verification code was sent to ${widget.phoneNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthCodeFields(
                            length: otpLength,
                            value: _otp,
                            focusedIndex: _currentFocusIndex,
                            onTap: _onOtpCircleTapped,
                            preferredWidth: 48,
                            height: 44,
                          ),
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                _errorMessage,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Resend code 0:${_resendTimer.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: _resendTimer == 0 ? _resendOTP : null,
                            child: Text(
                              "Send code",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: _resendTimer == 0
                                    ? colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              AuthNumericKeypad(
                onDigitPressed: _onDigitPressed,
                onClearPressed: _onClearPressed,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isOtpVerified && !_isVerifying
                      ? _onVerifyPressed
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOtpVerified && !_isVerifying
                        ? colorScheme.primary
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFFFFF),
                            ),
                          ),
                        )
                      : Text(
                          "Verify",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

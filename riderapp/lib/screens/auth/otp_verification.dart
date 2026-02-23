import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/button.dart';
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
    this.webConfirmationResult
  });

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  static const int otpLength = 6;

  final List<TextEditingController> _otpControllers =
      List.generate(otpLength, (ctx) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(otpLength, (ctx) => FocusNode());
  final List<Color> _otpFieldColors =
      List.generate(otpLength, (ctx) => Colors.grey);
  final List<bool> _otpFieldFocused =
      List.generate(otpLength, (ctx) => false);

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
    
    // Disable all focus nodes to prevent keyboard
    for (int i = 0; i < otpLength; i++) {
      _otpFocusNodes[i].canRequestFocus = false;
    }
    
    // Focus starts at first field
    _currentFocusIndex = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
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

  void _validateOTP() {
    if (_otp.length != otpLength) {
      setState(() {
        _isOtpVerified = false;
        _errorMessage = '';
        for (int i = 0; i < otpLength; i++) {
          if (i == _currentFocusIndex && _enteredDigits.length < otpLength) {
            _otpFieldColors[i] = Colors.blue; // Focused field is blue
            _otpFieldFocused[i] = true;
          } else if (i < _enteredDigits.length && _enteredDigits[i].isNotEmpty) {
            _otpFieldColors[i] = Colors.blue; // Filled fields are blue
            _otpFieldFocused[i] = false;
          } else {
            _otpFieldColors[i] = Colors.grey;
            _otpFieldFocused[i] = false;
          }
        }
      });
      return;
    }

    // All fields are filled
    setState(() {
      _isOtpVerified = true;
      _errorMessage = '';
      for (int i = 0; i < otpLength; i++) {
        _otpFieldColors[i] = Colors.blue; // Blue when all fields filled
        _otpFieldFocused[i] = false; // No focus when all filled
      }
      _currentFocusIndex = -1; // No field focused when all filled
    });
  }

  // Handle tap on OTP circle
  void _onOtpCircleTapped(int index) {
    // Only allow tapping on empty fields or the next empty field
    if (index < _enteredDigits.length) {
      // If tapping a filled field, move focus to it
      _currentFocusIndex = index;
    } else {
      // If tapping an empty field, move to the next empty field
      _currentFocusIndex = _enteredDigits.length;
      if (_currentFocusIndex >= otpLength) {
        _currentFocusIndex = -1; // All fields are filled
      }
    }
    
    setState(() {
      _validateOTP();
    });
  }

  // ---------------- KEYPAD ----------------
  void _onDigitPressed(String digit) {
    if (_enteredDigits.length < otpLength) {
      setState(() {
        _enteredDigits.add(digit);
        _errorMessage = ''; // Clear error when user starts typing again
        
        // Move focus to next field
        _currentFocusIndex = _enteredDigits.length;
        if (_currentFocusIndex >= otpLength) {
          _currentFocusIndex = -1; // All fields are filled
        }
      });
      
      _validateOTP();
    }
  }

  void _onClearPressed() {
    if (_enteredDigits.isNotEmpty) {
      setState(() {
        _enteredDigits.removeLast();
        _errorMessage = ''; // Clear error when user starts typing again
        
        // Move focus to the cleared field
        _currentFocusIndex = _enteredDigits.length;
      });
      
      _validateOTP();
    }
  }

  // ---------------- ACTIONS ----------------
  void _resendOTP() {
    setState(() {
      _enteredDigits.clear();
      _errorMessage = '';
      _currentFocusIndex = 0;
      for (int i = 0; i < otpLength; i++) {
        _otpFieldColors[i] = Colors.grey;
        _otpControllers[i].clear();
        _otpFieldFocused[i] = false;
      }
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
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'OTP resent to ${widget.phoneNumber}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
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


    // Update OTP field colors for success
    setState(() {
      for (int i = 0; i < otpLength; i++) {
        _otpFieldColors[i] = Colors.green;
        _otpFieldFocused[i] = false;
      }
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'OTP verified successfully!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
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
    for (int i = 0; i < otpLength; i++) {
      _otpFieldColors[i] = Colors.red;
      _otpFieldFocused[i] = false;
    }
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
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Invalid OTP. Please try again.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
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


  // Helper to get border color based on state
  Color _getBorderColor(int index) {
    if (_otpFieldColors[index] == Colors.red) return Colors.red;
    if (_otpFieldColors[index] == Colors.green) return Colors.green;
    if (_otpFieldFocused[index]) return Colors.blue;
    if (index < _enteredDigits.length && _enteredDigits[index].isNotEmpty) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title:
          Text(
            "Enter the code",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Centered verification text in TWO lines
              Center(
                child: Text(
                  'A verification code was sent to ${widget.phoneNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // CIRCULAR OTP boxes - NO TEXTFIELD
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(otpLength, (index) {
                      return GestureDetector(
                        onTap: () => _onOtpCircleTapped(index),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getBorderColor(index),
                              width: 2,
                            ),
                            boxShadow: _otpFieldFocused[index] 
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            index < _enteredDigits.length ? _enteredDigits[index] : '',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Error message aligned with start of circles
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4),
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

              // Resend row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resend code 0:${_resendTimer.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: _resendTimer == 0 ? _resendOTP : null,
                    child: Text(
                      "Send code",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _resendTimer == 0
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Keypad
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Row 1: 1, 2, 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Button(digit: '1', onPressed: () => _onDigitPressed('1')),
                        Button(digit: '2', onPressed: () => _onDigitPressed('2')),
                        Button(digit: '3', onPressed: () => _onDigitPressed('3')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Row 2: 4, 5, 6
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Button(digit: '4', onPressed: () => _onDigitPressed('4')),
                        Button(digit: '5', onPressed: () => _onDigitPressed('5')),
                        Button(digit: '6', onPressed: () => _onDigitPressed('6')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Row 3: 7, 8, 9
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Button(digit: '7', onPressed: () => _onDigitPressed('7')),
                        Button(digit: '8', onPressed: () => _onDigitPressed('8')),
                        Button(digit: '9', onPressed: () => _onDigitPressed('9')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Row 4: 0 and clear button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 80, height: 80),
                        Button(digit: '0', onPressed: () => _onDigitPressed('0')),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: IconButton(
                            onPressed: _onClearPressed,
                            icon: const Icon(Icons.backspace_outlined, size: 28),
                            style: IconButton.styleFrom(
                              shape: const CircleBorder(),
                              backgroundColor: Colors.grey[200],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isOtpVerified && !_isVerifying ? _onVerifyPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isOtpVerified && !_isVerifying ? Colors.blue : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isVerifying
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : Text(
                          "Verify",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

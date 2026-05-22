import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_verification.dart';
import '../../components/auth_components.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => SignUpScreenState();
}

class SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+234';
  //ignore: unused_field
  String _selectedCountryFlag = '🇳🇬';
  bool _isPhoneValid = false;
  String _phoneError = '';
  bool _isPhoneInputFocused = false;
  final List<String> _enteredDigits = [];

  final List<Map<String, String>> _countries = [
    {'flag': '🇳🇬', 'code': '+234', 'name': 'Nigeria'},
    {'flag': '🇺🇸', 'code': '+1', 'name': 'USA'},
    {'flag': '🇬🇧', 'code': '+44', 'name': 'UK'},
    {'flag': '🇨🇦', 'code': '+1', 'name': 'Canada'},
    {'flag': '🇫🇷', 'code': '+33', 'name': 'France'},
    {'flag': '🇩🇪', 'code': '+49', 'name': 'Germany'},
    {'flag': '🇮🇳', 'code': '+91', 'name': 'India'},
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhoneNumber() {
    final String phoneDigits = _enteredDigits.join('');
    if (phoneDigits.length == 10) {
      setState(() {
        _isPhoneValid = true;
        _phoneError = '';
      });
    } else if (phoneDigits.length > 10) {
      setState(() {
        _isPhoneValid = false;
        _phoneError = 'Phone number should be 10 digits';
      });
    } else if (phoneDigits.isNotEmpty && phoneDigits.length < 10) {
      setState(() {
        _isPhoneValid = false;
        _phoneError = 'Phone number should be 10 digits';
      });
    } else {
      setState(() {
        _isPhoneValid = false;
        _phoneError = '';
      });
    }
  }

  // Format phone number as 3 3 4
  String _formatPhoneNumber(List<String> digits) {
    String result = '';
    for (int i = 0; i < digits.length; i++) {
      result += digits[i];
      if (i == 2 || i == 5) result += ' ';
    }
    return result;
  }

  void _onDigitPressed(String digit) {
    if (_enteredDigits.length < 10) {
      setState(() {
        _isPhoneInputFocused = true;
        _enteredDigits.add(digit);
        _phoneController.text = _formatPhoneNumber(_enteredDigits);
      });
      _validatePhoneNumber();
    }
  }

  void _onClearPressed() {
    if (_enteredDigits.isNotEmpty) {
      setState(() {
        _isPhoneInputFocused = true;
        _enteredDigits.removeLast();
        _phoneController.text = _formatPhoneNumber(_enteredDigits);
      });
      _validatePhoneNumber();
    }
  }

  void _clearPhoneNumber() {
    setState(() {
      _isPhoneInputFocused = true;
      _enteredDigits.clear();
      _phoneController.clear();
    });
    _validatePhoneNumber();
  }

  void _onCountryChanged(Map<String, String> country) {
    setState(() {
      _selectedCountryCode = country['code']!;
      _selectedCountryFlag = country['flag']!;
    });
  }

  void _navigateToOTPScreen() async {
    final String fullPhoneNumber =
        '$_selectedCountryCode${_enteredDigits.join()}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final auth = ref.read(authProvider);
      await auth.sendVerificationCode(
        phoneNumber: fullPhoneNumber,
        onCodeSent: () {
          if (!mounted) return;
          Navigator.pop(context);

          // Navigate to OTP screen AFTER codeSent
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) =>
                  OTPScreen(phoneNumber: fullPhoneNumber, verificationId: ''),
            ),
          );
        },
        onFailed: (e) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP: ${e.message}')),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

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
            ? Colors.black
            : Colors.white,
        centerTitle: true,
        title: Text(
          "Enter your number",
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'We will send a verification code via SMS',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      AuthPhoneInput(
                        countries: _countries,
                        selectedCountryCode: _selectedCountryCode,
                        phoneText: _phoneController.text,
                        errorText: _phoneError,
                        isFocused: _isPhoneInputFocused,
                        onCountryChanged: _onCountryChanged,
                        onTap: () {
                          setState(() => _isPhoneInputFocused = true);
                        },
                        onClear: _clearPhoneNumber,
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: Center(
                          child: AuthNumericKeypad(
                            onDigitPressed: _onDigitPressed,
                            onClearPressed: _onClearPressed,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isPhoneValid
                              ? _navigateToOTPScreen
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPhoneValid
                                ? colorScheme.primary
                                : Colors.grey[300],
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

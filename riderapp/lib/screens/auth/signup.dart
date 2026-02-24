import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_verification.dart';
import '../../components/button.dart';
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
        _enteredDigits.add(digit);
        _phoneController.text = _formatPhoneNumber(_enteredDigits);
      });
      _validatePhoneNumber();
    }
  }

  void _onClearPressed() {
    if (_enteredDigits.isNotEmpty) {
      setState(() {
        _enteredDigits.removeLast();
        _phoneController.text = _formatPhoneNumber(_enteredDigits);
      });
      _validatePhoneNumber();
    }
  }

  void _onCountryChanged(Map<String, String> country) {
    setState(() {
      _selectedCountryCode = country['code']!;
      _selectedCountryFlag = country['flag']!;
    });
  }

  void _navigateToOTPScreen() async {
  final String fullPhoneNumber = '$_selectedCountryCode${_enteredDigits.join()}';

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
            builder: (ctx) => OTPScreen(
              phoneNumber: fullPhoneNumber, verificationId: '',
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded, 
            size: 28
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title:
            Text(
              "Enter your number",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                ),
              ),
             const SizedBox(height: 40),

              // Phone input row
              Row(
                children: [
                  // Country dropdown
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, String>>(
                        value: _countries.firstWhere(
                          (country) => country['code'] == _selectedCountryCode,
                        ),
                        items: _countries.map((country) {
                          return DropdownMenuItem<Map<String, String>>(
                            value: country,
                            child: Row(
                              children: [Text(country['flag']!)],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => _onCountryChanged(value!),
                        icon: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Phone number input
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _phoneError.isNotEmpty
                              ? Colors.red
                              : _enteredDigits.isNotEmpty
                                  ? Colors.blue
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _selectedCountryCode,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(width: 1, height: 24, color: Colors.grey[400]),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _phoneController.text,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

             if (_phoneError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        left: 12 + 48 + 12 + 16,
                      ),
                      child: Text(
                        _phoneError,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                      ),
                    ),

              const SizedBox(height: 32),

               // Custom numeric keypad
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

              // Continue button
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isPhoneValid ? _navigateToOTPScreen : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPhoneValid ? Colors.blue : Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

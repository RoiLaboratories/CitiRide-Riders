import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/auth_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+234';
  //ignore: unused_field
  String _selectedCountryFlag = '🇳🇬';
  bool _isPhoneValid = false;
  String _phoneError = '';
  bool _isPhoneInputFocused = false;
  bool _isCheckingUser = false;
  final List<String> _enteredDigits = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Format phone number as 2 4 4
  String _formatPhoneNumber(List<String> digits) {
    String result = '';
    for (int i = 0; i < digits.length; i++) {
      result += digits[i];
      if (i == 1 || i == 5) result += ' ';
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

  void _onCountryChanged(Map<String, String> country) {
    setState(() {
      _selectedCountryCode = country['code']!;
      _selectedCountryFlag = country['flag']!;
    });
  }

  // Check if user exists in Firestore
  Future<bool> _checkUserExists(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user: $e');
      return false;
    }
  }

  // Show custom snackbar from top
  void _showCustomSnackbar(String message, {bool isError = true}) {
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
              color: isError ? Colors.red : Colors.green,
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
                message,
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

  void _handleLogin() async {
    final String fullPhoneNumber =
        '$_selectedCountryCode${_enteredDigits.join()}';

    setState(() {
      _isCheckingUser = true;
    });

    try {
      // Check if user exists
      final userExists = await _checkUserExists(fullPhoneNumber);
      if (!mounted) return;

      if (userExists) {
        // User exists - navigate directly to home screen
        setState(() {
          _isCheckingUser = false;
        });

        // Show success message
        _showCustomSnackbar('Welcome back!', isError: false);

        // Navigate to home screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        });
      } else {
        // User doesn't exist - show error message
        setState(() {
          _isCheckingUser = false;
        });

        // Show error message
        _showCustomSnackbar('No user found with this phone number');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingUser = false;
      });
      _showCustomSnackbar('Error: $e');
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
            ? Colors.white
            : Colors.black,
        centerTitle: true,
        title: Text(
          "Login",
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
                          'Enter your phone number to login',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
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
                          onPressed: (_isPhoneValid && !_isCheckingUser)
                              ? _handleLogin
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_isPhoneValid && !_isCheckingUser)
                                ? colorScheme.primary
                                : Colors.grey[300],
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: _isCheckingUser
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
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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

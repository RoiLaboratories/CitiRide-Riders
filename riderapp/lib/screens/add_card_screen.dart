import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum CardType { visa, mastercard, verve, unknown }

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _pinController = TextEditingController();

  CardType _cardType = CardType.unknown;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _cardNumberController.addListener(_onAnyFieldChanged);
    _expiryController.addListener(_onAnyFieldChanged);
    _cvvController.addListener(_onAnyFieldChanged);
    _pinController.addListener(_onAnyFieldChanged);
  }

  void _onAnyFieldChanged() {
    setState(() {
      _cardType = _detectCardType(
        _cardNumberController.text.replaceAll(' ', ''),
      );
    });
  }

  // ---------------- CARD TYPE ----------------

  CardType _detectCardType(String input) {
    if (input.length < 4) return CardType.unknown;
    if (input.startsWith('4')) return CardType.visa;
    if (input.startsWith(RegExp(r'5[1-5]'))) return CardType.mastercard;
    if (input.startsWith(RegExp(r'(506|650)'))) return CardType.verve;
    return CardType.unknown;
  }

  bool _luhnCheck(String number) {
    if (number.length < 16) return false;
    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  bool get _isFormValid {
    final card = _cardNumberController.text.replaceAll(' ', '');
    return _luhnCheck(card) &&
        _expiryController.text.length == 5 &&
        _cvvController.text.length == 3 &&
        _pinController.text.length == 4;
  }

  // ---------------- CONTINUE ----------------

  Future<void> _verifyCard() async {
    if (!_isFormValid) return;

    setState(() => _loading = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() => _loading = false);

    Navigator.pushReplacementNamed(context, '/top-up');
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.citiRideColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'Add Debit Card',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 22,
            color: colors.text,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'To ensure the security of your funds, you can\nonly add a bank card linked to your BVN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.grey
                ),
              ),
            ),
            const SizedBox(height: 60),

            _label('Card Number'),
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              decoration: _inputDecoration(
                hint: '16 digits card number',
                prefix: _cardLogo(),
              ),
            ),

            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Valid Thru'),
                      TextField(
                        controller: _expiryController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                          _ExpiryDateFormatter(),
                        ],
                        decoration: _inputDecoration(hint: 'MM/YY'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('CVV'),
                      TextField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: _inputDecoration(hint: '123'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            _label('Card PIN'),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: _inputDecoration(hint: '****'),
            ),

            const Spacer(),
            Center(
              child: SizedBox(
                width: 353,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isFormValid && !_loading ? _verifyCard : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.35),
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor: colorScheme.primary.withValues(
                      alpha: 0.35,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _loading
                      ? CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                        )
                      : Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _cardLogo() {
    Widget logo;

    switch (_cardType) {
      case CardType.visa:
        logo = Image.asset('images/visa.png', width: 28);
        break;
      case CardType.mastercard:
        logo = Image.asset('images/master.png', width: 28);
        break;
      case CardType.verve:
        logo = Image.asset('images/verve.png', width: 28);
        break;
      default:
        logo = const SizedBox();
    }

    return SizedBox(
      width: 48,
      child: Center(child: logo),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      prefixIcon: prefix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}

// ---------------- FORMATTERS ----------------

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i % 4 == 0 && i != 0) buffer.write(' ');
      buffer.write(digits[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (text.length >= 3 && !text.contains('/')) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateWalletPinScreen extends StatefulWidget {
  const CreateWalletPinScreen({super.key, this.isResetFlow = false});

  final bool isResetFlow;

  @override
  State<CreateWalletPinScreen> createState() => _CreateWalletPinScreenState();
}

class _CreateWalletPinScreenState extends State<CreateWalletPinScreen> {
  String _draftPin = '';
  String _inputPin = '';
  bool _isConfirmStep = false;
  bool _isSaving = false;
  String? _errorText;

  Future<void> _onBackPressed() async {
    if (_isConfirmStep) {
      setState(() {
        _isConfirmStep = false;
        _inputPin = '';
        _errorText = null;
      });
      return;
    }
    Navigator.pop(context, false);
  }

  void _onDigitPressed(String digit) {
    if (_inputPin.length >= 4 || _isSaving) return;
    setState(() {
      _inputPin += digit;
      _errorText = null;
    });
  }

  void _onDeletePressed() {
    if (_inputPin.isEmpty || _isSaving) return;
    setState(() {
      _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      _errorText = null;
    });
  }

  Future<void> _onNextPressed() async {
    if (_inputPin.length != 4 || _isSaving) return;

    if (!_isConfirmStep) {
      setState(() {
        _draftPin = _inputPin;
        _inputPin = '';
        _isConfirmStep = true;
      });
      return;
    }

    if (_inputPin != _draftPin) {
      setState(() {
        _errorText = 'PIN does not match. Try again.';
        _inputPin = '';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallet_pin', _inputPin);
      await prefs.setString(
        'wallet_pin_last_updated',
        DateTime.now().toIso8601String(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isResetFlow
                ? 'Wallet PIN reset successfully'
                : 'Wallet PIN created successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Could not save PIN. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save PIN: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _pinBox(int index) {
    final hasValue = index < _inputPin.length;
    final value = hasValue ? _inputPin[index] : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1E88E5), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Color(0x4DB3DBFF), spreadRadius: 1.6, blurRadius: 0),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 22,
          color: Color(0xFF2D2E3A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _numberButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFFE6E6E8),
          foregroundColor: const Color(0xFF2D2E3A),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: icon != null
            ? Icon(icon, size: 28, color: const Color(0xFF8A8D93))
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF2D2E3A),
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _clearButton() {
    return SizedBox(
      width: 80,
      height: 80,
      child: IconButton(
        onPressed: _onDeletePressed,
        icon: const Icon(Icons.backspace_outlined, size: 28),
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFFE6E6E8),
          foregroundColor: const Color(0xFF8A8D93),
        ),
      ),
    );
  }

  Widget _numberRow(String a, String b, String c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _numberButton(label: a, onTap: () => _onDigitPressed(a)),
        _numberButton(label: b, onTap: () => _onDigitPressed(b)),
        _numberButton(label: c, onTap: () => _onDigitPressed(c)),
      ],
    );
  }

  Widget _lastRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 80, height: 80),
        _numberButton(label: '0', onTap: () => _onDigitPressed('0')),
        _clearButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isConfirmStep
        ? 'Confirm PIN'
        : (widget.isResetFlow ? 'Reset PIN' : 'Create PIN');
    final subtitle = _isConfirmStep
        ? 'Confirm your 4-digit PIN'
        : 'Create a PIN to secure your Sureride transactions';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F4),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isSaving ? null : _onBackPressed,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 26,
                      ),
                      color: const Color(0xFF2D2E3A),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 46),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2E3A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8A8D93),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, _pinBox),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _numberRow('1', '2', '3'),
                    const SizedBox(height: 20),
                    _numberRow('4', '5', '6'),
                    const SizedBox(height: 20),
                    _numberRow('7', '8', '9'),
                    const SizedBox(height: 20),
                    _lastRow(),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _inputPin.length == 4 && !_isSaving
                        ? _onNextPressed
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1690F0),
                      disabledBackgroundColor: const Color(0xFF8BC8F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isConfirmStep ? 'Confirm' : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
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

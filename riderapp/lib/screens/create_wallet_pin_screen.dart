import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/auth_components.dart';
import '../theme/app_theme.dart';

class CreateWalletPinScreen extends StatefulWidget {
  const CreateWalletPinScreen({super.key, this.isResetFlow = false});

  final bool isResetFlow;

  @override
  State<CreateWalletPinScreen> createState() => _CreateWalletPinScreenState();
}

class _CreateWalletPinScreenState extends State<CreateWalletPinScreen> {
  static const int _pinLength = 6;

  String _draftPin = '';
  String _inputPin = '';
  bool _isConfirmStep = false;
  bool _isSaving = false;
  String? _errorText;

  int get _focusedPinIndex =>
      _inputPin.length < _pinLength && !_isSaving ? _inputPin.length : -1;

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
    if (_inputPin.length >= _pinLength || _isSaving) return;
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
    if (_inputPin.length != _pinLength || _isSaving) return;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = _isConfirmStep
        ? 'Confirm PIN'
        : (widget.isResetFlow ? 'Reset PIN' : 'Create PIN');
    final subtitle = _isConfirmStep
        ? 'Confirm your 6-digit PIN'
        : 'Create a 6-digit PIN to secure your CitiRide transactions';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        backgroundColor:
            Theme.of(context).extension<CitiRideThemeColors>()?.surface ??
            const Color(0xFFF2F2F4),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
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
                          padding: const EdgeInsets.symmetric(horizontal: 26),
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
                        AuthCodeFields(
                          length: _pinLength,
                          value: _inputPin,
                          focusedIndex: _focusedPinIndex,
                          preferredWidth: 54,
                          height: 56,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            color: Color(0xFF2D2E3A),
                            fontWeight: FontWeight.w500,
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
                        const SizedBox(height: 24),
                        Expanded(
                          child: Center(
                            child: AuthNumericKeypad(
                              onDigitPressed: _onDigitPressed,
                              onClearPressed: _onDeletePressed,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                _inputPin.length == _pinLength && !_isSaving
                                ? _onNextPressed
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              disabledBackgroundColor: colorScheme.primary
                                  .withValues(alpha: 0.45),
                              disabledForegroundColor: colorScheme.onPrimary
                                  .withValues(alpha: 0.65),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
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
            },
          ),
        ),
      ),
    );
  }
}

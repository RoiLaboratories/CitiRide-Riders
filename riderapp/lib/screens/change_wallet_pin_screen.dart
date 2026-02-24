import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeWalletPinScreen extends StatefulWidget {
  const ChangeWalletPinScreen({super.key});

  @override
  State<ChangeWalletPinScreen> createState() => _ChangeWalletPinScreenState();
}

class _ChangeWalletPinScreenState extends State<ChangeWalletPinScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isSaving = false;
  bool _hasExistingPin = false;
  String _storedPin = '';

  @override
  void initState() {
    super.initState();
    _loadExistingPin();
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('wallet_pin') ?? '';

    if (!mounted) return;

    setState(() {
      _storedPin = pin;
      _hasExistingPin = pin.isNotEmpty;
    });
  }

  Future<void> _savePin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasExistingPin && _currentPinController.text.trim() != _storedPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current PIN is incorrect'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final newPin = _newPinController.text.trim();
      await prefs.setString('wallet_pin', newPin);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet PIN updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update wallet PIN: $e'),
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

  Widget _pinField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          validator: validator,
          decoration: InputDecoration(
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF1F7BFF)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Change Wallet PIN',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            const Text(
              'Your wallet PIN protects transfers and payments.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            if (_hasExistingPin) ...[
              _pinField(
                label: 'Current PIN',
                controller: _currentPinController,
                validator: (value) {
                  if (_hasExistingPin && (value == null || value.length != 4)) {
                    return 'Enter your current 4-digit PIN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],
            _pinField(
              label: _hasExistingPin ? 'New PIN' : 'Create PIN',
              controller: _newPinController,
              validator: (value) {
                if (value == null || value.length != 4) {
                  return 'PIN must be 4 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _pinField(
              label: 'Confirm PIN',
              controller: _confirmPinController,
              validator: (value) {
                if ((value ?? '').trim() != _newPinController.text.trim()) {
                  return 'PIN does not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Update wallet PIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

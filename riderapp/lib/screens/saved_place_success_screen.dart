import 'package:flutter/material.dart';

import '../models/saved_place_type.dart';

class SavedPlaceSuccessScreen extends StatelessWidget {
  const SavedPlaceSuccessScreen({
    super.key,
    required this.placeType,
  });

  final SavedPlaceType placeType;

  void _backToHome(BuildContext context) {
    Navigator.of(
      context,
    ).popUntil((route) => route.settings.name == '/home' || route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 128,
                height: 128,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF19D652),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                placeType.successTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 33,
                  height: 1.15,
                  color: Color(0xFF2D2F3A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _backToHome(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1690F0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Back To Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

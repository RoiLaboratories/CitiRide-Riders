import 'package:flutter/material.dart';

import '../models/saved_place_type.dart';
import '../theme/app_theme.dart';

class SavedPlaceSuccessScreen extends StatelessWidget {
  const SavedPlaceSuccessScreen({super.key, required this.placeType});

  final SavedPlaceType placeType;

  void _backToHome(BuildContext context) {
    Navigator.of(
      context,
    ).popUntil((route) => route.settings.name == '/home' || route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            children: [
              SizedBox(
                height: 54,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF19D652),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 68,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 34),
              Text(
                placeType.successTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.45,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _backToHome(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CitiRideTheme.primaryYellow,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Back To Home',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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

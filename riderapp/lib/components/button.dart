import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class Button extends StatelessWidget {
  final String digit;
  final VoidCallback onPressed;

  const Button({
    super.key, 
    required this.digit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: colors.surfaceAlt,
          foregroundColor: colors.text,
          elevation: 0,
        ),
        child: Text(
          digit,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

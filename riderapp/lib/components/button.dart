import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Button extends StatelessWidget {
  final String digit;
  final VoidCallback onPressed;

  const Button({super.key, required this.digit, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: InkResponse(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: const Color(0xFFB0B0B0), width: 0.8),
          ),
          child: Text(
            digit,
            style: GoogleFonts.poppins(
              fontSize: 35,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E90),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

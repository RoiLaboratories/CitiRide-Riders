import 'package:flutter/material.dart';

/// COLORS
const kPrimaryBlue = Color(0xFFF5E700);
const kTextGrey = Color(0xFF8E8E93);
const kLightGrey = Color(0xFFF2F2F2);
const kDriverPurple = Color(0xFF6B4EFF);

/// FLOATING MODAL DECORATION
BoxDecoration floatingSheetDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 55),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

/// DRAG HANDLE
Widget dragHandle() {
  return Container(
    width: 36,
    height: 5,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

/// PRIMARY BUTTON (353 x 52)
Widget primaryButton({
  required String text,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: 353,
    height: 52,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  );
}

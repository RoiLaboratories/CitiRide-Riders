import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'button.dart';

const Color authInputFillColor = Color(0xFFEDEEF1);
const Color authInputFocusColor = CitiRideTheme.primaryYellow;

BorderRadius authPillRadius(double height) => BorderRadius.circular(height / 2);

BoxDecoration authPillDecoration({
  required bool isFocused,
  double height = 48,
  Color fillColor = authInputFillColor,
  Color focusColor = authInputFocusColor,
}) {
  return BoxDecoration(
    color: fillColor,
    borderRadius: authPillRadius(height),
    border: isFocused ? Border.all(color: focusColor, width: 2) : null,
  );
}

InputDecoration authPinInputDecoration(BuildContext context) {
  final colors = context.citiRideColors;
  final borderRadius = authPillRadius(48);
  final baseBorder = OutlineInputBorder(
    borderRadius: borderRadius,
    borderSide: BorderSide.none,
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: borderRadius,
    borderSide: BorderSide(
      color: Theme.of(context).colorScheme.primary,
      width: 2,
    ),
  );

  return InputDecoration(
    counterText: '',
    filled: true,
    fillColor: colors.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    border: baseBorder,
    enabledBorder: baseBorder,
    focusedBorder: focusedBorder,
    errorBorder: baseBorder,
    focusedErrorBorder: focusedBorder,
  );
}

class AuthPhoneInput extends StatelessWidget {
  const AuthPhoneInput({
    super.key,
    required this.countries,
    required this.selectedCountryCode,
    required this.phoneText,
    required this.errorText,
    required this.isFocused,
    required this.onCountryChanged,
    required this.onTap,
  });

  final List<Map<String, String>> countries;
  final String selectedCountryCode;
  final String phoneText;
  final String errorText;
  final bool isFocused;
  final ValueChanged<Map<String, String>> onCountryChanged;
  final VoidCallback onTap;

  static const double _countryWidth = 84;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: _countryWidth,
              height: 48,
              child: Container(
                decoration: authPillDecoration(
                  isFocused: false,
                  fillColor: colors.inputFill,
                  focusColor: primary,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, String>>(
                    value: countries.firstWhere(
                      (country) => country['code'] == selectedCountryCode,
                    ),
                    isExpanded: true,
                    items: countries.map((country) {
                      return DropdownMenuItem<Map<String, String>>(
                        value: country,
                        child: Text(country['flag']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) onCountryChanged(value);
                    },
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 48,
                  decoration: authPillDecoration(
                    isFocused: isFocused,
                    fillColor: colors.inputFill,
                    focusColor: primary,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          selectedCountryCode,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.text,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey.shade400,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            phoneText,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 1,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: _countryWidth + 28),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }
}

class AuthCodeFields extends StatelessWidget {
  const AuthCodeFields({
    super.key,
    required this.length,
    required this.value,
    required this.focusedIndex,
    this.onTap,
    this.preferredWidth = 64,
    this.height = 52,
    this.textStyle,
  });

  final int length;
  final String value;
  final int focusedIndex;
  final ValueChanged<int>? onTap;
  final double preferredWidth;
  final double height;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;
    final primary = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final availableWidth = math.max(0, constraints.maxWidth);
        final maxFieldWidth = math.max(
          0,
          (availableWidth - gap * (length - 1)) / length,
        );
        final minimumFlatWidth = math.min(height + 8, maxFieldWidth);
        final fieldWidth = math.max(
          minimumFlatWidth,
          math.min(preferredWidth, maxFieldWidth),
        ).toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(length, (index) {
            final isFocused = index == focusedIndex;
            final text = index < value.length ? value[index] : '';

            return GestureDetector(
              onTap: onTap == null ? null : () => onTap!(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: fieldWidth,
                height: height,
                alignment: Alignment.center,
                decoration: authPillDecoration(
                  isFocused: isFocused,
                  height: height,
                  fillColor: colors.inputFill,
                  focusColor: primary,
                ),
                child: Text(
                  text,
                  style:
                      textStyle ??
                      GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class AuthNumericKeypad extends StatelessWidget {
  const AuthNumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onClearPressed,
    this.rowSpacing = 20,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onClearPressed;
  final double rowSpacing;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _numberRow('1', '2', '3'),
        SizedBox(height: rowSpacing),
        _numberRow('4', '5', '6'),
        SizedBox(height: rowSpacing),
        _numberRow('7', '8', '9'),
        SizedBox(height: rowSpacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80, height: 80),
            Button(digit: '0', onPressed: () => onDigitPressed('0')),
            SizedBox(
              width: 80,
              height: 80,
              child: IconButton(
                onPressed: onClearPressed,
                icon: const Icon(Icons.backspace_outlined, size: 28),
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: colors.surfaceAlt,
                  foregroundColor: colors.text,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberRow(String a, String b, String c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Button(digit: a, onPressed: () => onDigitPressed(a)),
        Button(digit: b, onPressed: () => onDigitPressed(b)),
        Button(digit: c, onPressed: () => onDigitPressed(c)),
      ],
    );
  }
}

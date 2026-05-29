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
    this.onClear,
  });

  final List<Map<String, String>> countries;
  final String selectedCountryCode;
  final String phoneText;
  final String errorText;
  final bool isFocused;
  final ValueChanged<Map<String, String>> onCountryChanged;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  static const double _countryWidth = 94;
  static const double _inputHeight = 58;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFEFEFF4);
    const fillColor = Colors.transparent;
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF151515);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: _countryWidth,
              height: _inputHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(_inputHeight / 2),
                  border: Border.all(color: borderColor, width: 1.6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, String>>(
                    value: countries.firstWhere(
                      (country) => country['code'] == selectedCountryCode,
                    ),
                    isExpanded: true,
                    dropdownColor: const Color(0xFF151515),
                    items: countries.map((country) {
                      return DropdownMenuItem<Map<String, String>>(
                        value: country,
                        child: Text(
                          country['flag']!,
                          style: const TextStyle(fontSize: 23),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) onCountryChanged(value);
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: borderColor,
                      size: 30,
                    ),
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
                  height: _inputHeight,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(_inputHeight / 2),
                    border: Border.all(color: borderColor, width: 1.6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 10),
                          child: Text(
                            phoneText.isEmpty ? '123 456 7890' : phoneText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 1,
                              color: phoneText.isEmpty
                                  ? const Color(0xFF8E8E90)
                                  : textColor,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: onClear,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2D2F3A),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 24,
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
    this.preferredWidth = 76,
    this.height = 58,
    this.textStyle,
    this.feedbackBorderColor,
  });

  final int length;
  final String value;
  final int focusedIndex;
  final ValueChanged<int>? onTap;
  final double preferredWidth;
  final double height;
  final TextStyle? textStyle;
  final Color? feedbackBorderColor;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF151515);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final availableWidth = math.max(0, constraints.maxWidth);
        final maxFieldWidth = math.max(
          0,
          (availableWidth - gap * (length - 1)) / length,
        );
        final minimumFlatWidth = math.min(height + 8, maxFieldWidth);
        final fieldWidth = math
            .max(minimumFlatWidth, math.min(preferredWidth, maxFieldWidth))
            .toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(length, (index) {
            final isFocused = index == focusedIndex;
            final text = index < value.length ? value[index] : '';
            final isFilled = text.isNotEmpty;

            return GestureDetector(
              onTap: onTap == null ? null : () => onTap!(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: fieldWidth,
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isFilled ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(height / 2),
                  border: Border.all(
                    color:
                        feedbackBorderColor ??
                        (isFocused || isFilled
                            ? primary
                            : const Color(0xFFEFEFF4)),
                    width: 1.6,
                  ),
                ),
                child: Text(
                  text,
                  style:
                      textStyle ??
                      GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.w500,
                        color: isFilled ? const Color(0xFF2D2F3A) : textColor,
                        height: 1,
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
    this.rowSpacing = 22,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onClearPressed;
  final double rowSpacing;

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(width: 72, height: 72),
            Button(digit: '0', onPressed: () => onDigitPressed('0')),
            SizedBox(
              width: 72,
              height: 72,
              child: InkResponse(
                onTap: onClearPressed,
                customBorder: const CircleBorder(),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFFB0B0B0),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.backspace_rounded,
                    size: 32,
                    color: Color(0xFF8E8E90),
                  ),
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

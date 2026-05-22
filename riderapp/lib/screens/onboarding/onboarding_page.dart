import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/onboarding_model.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 620;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(child: Image.asset(data.heroImage, fit: BoxFit.cover)),
                SizedBox(height: compact ? 24 : 45),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: data.titleParts.map((part) {
                        if (part.text != null) {
                          return TextSpan(
                            text: part.text,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          );
                        } else {
                          return WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Image.asset(part.image!, height: 28),
                            ),
                          );
                        }
                      }).toList(),
                    ),
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

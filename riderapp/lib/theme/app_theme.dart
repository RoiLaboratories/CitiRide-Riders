import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class CitiRideThemeColors extends ThemeExtension<CitiRideThemeColors> {
  const CitiRideThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.mutedText,
    required this.inputFill,
    required this.border,
    required this.primaryBlur,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color mutedText;
  final Color inputFill;
  final Color border;
  final Color primaryBlur;

  @override
  CitiRideThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? text,
    Color? mutedText,
    Color? inputFill,
    Color? border,
    Color? primaryBlur,
  }) {
    return CitiRideThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      text: text ?? this.text,
      mutedText: mutedText ?? this.mutedText,
      inputFill: inputFill ?? this.inputFill,
      border: border ?? this.border,
      primaryBlur: primaryBlur ?? this.primaryBlur,
    );
  }

  @override
  CitiRideThemeColors lerp(
    ThemeExtension<CitiRideThemeColors>? other,
    double t,
  ) {
    if (other is! CitiRideThemeColors) return this;

    return CitiRideThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      text: Color.lerp(text, other.text, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      border: Color.lerp(border, other.border, t)!,
      primaryBlur: Color.lerp(primaryBlur, other.primaryBlur, t)!,
    );
  }
}

class CitiRideTheme {
  const CitiRideTheme._();

  static const Color primaryYellow = Color(0xFFF5E700);
  static const Color brightYellow = Color(0xFFFFF331);
  static const Color darkBackground = Color(0xFF0F0C09);
  static const Color darkSurface = Color(0xFF171717);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF2F2F4);

  static const CitiRideThemeColors darkColors = CitiRideThemeColors(
    background: darkBackground,
    surface: darkSurface,
    surfaceAlt: Color(0xFF242424),
    text: Color(0xFFF7F7F7),
    mutedText: Color(0xFF9B9B9B),
    inputFill: Color(0xFF222222),
    border: Color(0xFF4F4F4F),
    primaryBlur: Color(0x4DF5E700),
  );

  static const CitiRideThemeColors lightColors = CitiRideThemeColors(
    background: lightBackground,
    surface: lightSurface,
    surfaceAlt: Color(0xFFEDEEF1),
    text: Color(0xFF0F0C09),
    mutedText: Color(0xFF6F737C),
    inputFill: Color(0xFFEDEEF1),
    border: Color(0xFFD7D9DF),
    primaryBlur: Color(0x33F5E700),
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    colors: darkColors,
    onPrimary: Colors.black,
  );

  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    colors: lightColors,
    onPrimary: darkBackground,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required CitiRideThemeColors colors,
    required Color onPrimary,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryYellow,
      onPrimary: onPrimary,
      secondary: brightYellow,
      onSecondary: darkBackground,
      error: const Color(0xFFFF3B3B),
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.text,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      extensions: <ThemeExtension<dynamic>>[colors],
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: colors.text,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colors.text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.45),
          disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.65),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        hintStyle: TextStyle(color: colors.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : colors.mutedText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF11B51A)
              : colors.border,
        ),
      ),
    );
  }
}

extension CitiRideThemeX on BuildContext {
  CitiRideThemeColors get citiRideColors =>
      Theme.of(this).extension<CitiRideThemeColors>() ??
      CitiRideTheme.darkColors;
}

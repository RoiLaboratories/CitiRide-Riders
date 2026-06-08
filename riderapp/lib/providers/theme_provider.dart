import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/legacy.dart';

class AppThemeNotifier extends ChangeNotifier {
  static const _preferenceKey = 'settings_light_theme';
  ThemeMode _themeMode = ThemeMode.dark;

  AppThemeNotifier() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isLightTheme => _themeMode == ThemeMode.light;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isLight = prefs.getBool(_preferenceKey) ?? false;
    _themeMode = isLight ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setLightTheme(bool value) async {
    _themeMode = value ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferenceKey, value);
  }
}

final appThemeControllerProvider =
    ChangeNotifierProvider<AppThemeNotifier>((ref) {
  return AppThemeNotifier();
});

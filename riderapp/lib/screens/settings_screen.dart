import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadPushPreference();
  }

  Future<void> _loadPushPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _pushNotifications = prefs.getBool('settings_push_notifications') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _onPushChanged(bool value) async {
    setState(() => _pushNotifications = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_push_notifications', value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;
    final themeController = ref.watch(appThemeControllerProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                title: Text(
                  'Enable push notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colors.text,
                  ),
                ),
                trailing: Transform.scale(
                  scale: 1.05,
                  child: Switch.adaptive(
                    value: _pushNotifications,
                    onChanged: _onPushChanged,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF11B51A),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 20, color: colors.border),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                title: Text(
                  'Light theme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colors.text,
                  ),
                ),
                trailing: Transform.scale(
                  scale: 1.05,
                  child: Switch.adaptive(
                    value: themeController.isLightTheme,
                    onChanged: themeController.setLightTheme,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF11B51A),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 20, color: colors.border),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                title: Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colors.text,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colors.mutedText,
                  size: 34,
                ),
                onTap: () => Navigator.pushNamed(context, '/security'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

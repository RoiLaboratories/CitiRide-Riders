import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F2F4),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 30,
            color: Color(0xFF2D2F3A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF2D2F3A),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                title: const Text(
                  'Enable push notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF30333F),
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 20),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                title: const Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF30333F),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA7ABB2),
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

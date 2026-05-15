import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const String _defaultNigerianPhone = '+2349070107455';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _phoneNumber = _defaultNigerianPhone;
  String _selectedCountryCode = '+234';
  String _selectedCountryFlag = '\u{1F1F3}\u{1F1EC}';
  String _selectedAvatarAsset = 'images/profile.png';
  Uint8List? _selectedAvatarBytes;
  bool _isLoading = true;
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();
  final List<Map<String, String>> _countries = const [
    {'flag': '\u{1F1F3}\u{1F1EC}', 'code': '+234', 'name': 'Nigeria'},
    {'flag': '\u{1F1FA}\u{1F1F8}', 'code': '+1', 'name': 'USA'},
    {'flag': '\u{1F1EC}\u{1F1E7}', 'code': '+44', 'name': 'UK'},
    {'flag': '\u{1F1E8}\u{1F1E6}', 'code': '+1', 'name': 'Canada'},
    {'flag': '\u{1F1EB}\u{1F1F7}', 'code': '+33', 'name': 'France'},
    {'flag': '\u{1F1E9}\u{1F1EA}', 'code': '+49', 'name': 'Germany'},
    {'flag': '\u{1F1EE}\u{1F1F3}', 'code': '+91', 'name': 'India'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _safeText(dynamic value) => value is String ? value : '';

  Uint8List? _decodeAvatarBase64(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  void _applyPhoneInputState(String fullPhone) {
    final normalized = fullPhone.replaceAll(RegExp(r'\s+'), '').trim();
    final matchedCountry = _countries.firstWhere(
      (country) => normalized.startsWith(country['code'] ?? ''),
      orElse: () => _countries.first,
    );

    _selectedCountryCode = matchedCountry['code'] ?? '+234';
    _selectedCountryFlag = matchedCountry['flag'] ?? '\u{1F1F3}\u{1F1EC}';

    var localPhone = normalized;
    if (localPhone.startsWith(_selectedCountryCode)) {
      localPhone = localPhone.substring(_selectedCountryCode.length);
    }
    if (localPhone.startsWith('0')) {
      localPhone = localPhone.substring(1);
    }

    _phoneController.text = localPhone;
    _phoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: _phoneController.text.length),
    );
  }

  String _buildPhoneNumberForSave() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty
        ? _selectedCountryCode
        : '$_selectedCountryCode$digits';
  }

  Future<void> _loadProfile() async {
    final auth = ref.read(authProvider);
    final userData = await auth.getUserData();
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final localName = prefs.getString('profile_name') ?? '';
    final localUsername = prefs.getString('profile_username') ?? '';
    final localEmail = prefs.getString('profile_email') ?? '';
    final localPhone = prefs.getString('profile_phone') ?? '';
    final storedAvatarAsset = prefs.getString('profile_avatar_asset');
    final storedAvatarBase64 = prefs.getString('profile_avatar_base64') ?? '';
    final userPhoto = _safeText(userData?['photoURL']);
    final profileAvatarAsset =
        storedAvatarAsset != null && storedAvatarAsset.isNotEmpty
        ? storedAvatarAsset
        : (userPhoto.startsWith('images/') ? userPhoto : _selectedAvatarAsset);

    final userDisplayName = _safeText(userData?['displayName']);
    final userUsername = _safeText(userData?['username']);
    final userEmail = _safeText(userData?['email']);
    final userPhone = _safeText(userData?['phoneNumber']);
    final authPhone = auth.currentUser?.phoneNumber ?? '';
    final resolvedPhone = userPhone.isNotEmpty
        ? userPhone
        : (authPhone.isNotEmpty
              ? authPhone
              : (localPhone.isNotEmpty ? localPhone : _defaultNigerianPhone));

    _applyPhoneInputState(resolvedPhone);

    setState(() {
      _nameController.text = userDisplayName.isNotEmpty
          ? userDisplayName
          : localName;
      _usernameController.text = userUsername.isNotEmpty
          ? userUsername
          : localUsername;
      _emailController.text = userEmail.isNotEmpty ? userEmail : localEmail;
      _phoneNumber = resolvedPhone;
      _selectedAvatarAsset = profileAvatarAsset;
      _selectedAvatarBytes = _decodeAvatarBase64(storedAvatarBase64);
      _isLoading = false;
    });
  }

  Future<void> _chooseAvatar() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Upload photo',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withAlpha(82)),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    0,
                    18,
                    18 + MediaQuery.of(dialogContext).viewInsets.bottom,
                  ),
                  child: Material(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(22),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: SizedBox(
                              width: 54,
                              height: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: CitiRideTheme.primaryYellow,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload photo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            leading: const Icon(
                              Icons.photo_library_outlined,
                              color: CitiRideTheme.primaryYellow,
                            ),
                            title: const Text(
                              'Choose from gallery',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () async {
                              Navigator.of(dialogContext).pop();
                              await _pickAvatar(ImageSource.gallery);
                            },
                          ),
                          const SizedBox(height: 4),
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            leading: const Icon(
                              Icons.photo_camera_outlined,
                              color: CitiRideTheme.primaryYellow,
                            ),
                            title: const Text(
                              'Take a picture',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () async {
                              Navigator.of(dialogContext).pop();
                              await _pickAvatar(ImageSource.camera);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final encoded = base64Encode(bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_avatar_base64', encoded);
    await prefs.remove('profile_avatar_asset');
    await prefs.remove('profile_avatar_file');

    if (!mounted) return;
    setState(() {
      _selectedAvatarBytes = bytes;
      _selectedAvatarAsset = 'images/profile.png';
    });
  }

  ImageProvider _avatarImageProvider() {
    if (_selectedAvatarBytes != null && _selectedAvatarBytes!.isNotEmpty) {
      return MemoryImage(_selectedAvatarBytes!);
    }
    return AssetImage(_selectedAvatarAsset);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auth = ref.read(authProvider);
      final prefs = await SharedPreferences.getInstance();
      final name = _nameController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      _phoneNumber = _buildPhoneNumberForSave();
      String successMessage = 'Changes saved';

      await prefs.setString('profile_name', name);
      await prefs.setString('profile_username', username);
      await prefs.setString('profile_email', email);
      await prefs.setString('profile_phone', _phoneNumber);
      if (_selectedAvatarBytes != null && _selectedAvatarBytes!.isNotEmpty) {
        await prefs.setString(
          'profile_avatar_base64',
          base64Encode(_selectedAvatarBytes!),
        );
        await prefs.remove('profile_avatar_asset');
        await prefs.remove('profile_avatar_file');
      } else {
        await prefs.setString('profile_avatar_asset', _selectedAvatarAsset);
        await prefs.remove('profile_avatar_base64');
      }

      if (auth.currentUser != null) {
        try {
          await auth.updateUserProfile(
            displayName: name,
            username: username,
            email: email,
            photoURL: _selectedAvatarAsset,
          );
        } catch (_) {
          successMessage = 'Saved locally. Sync will retry later.';
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save changes: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _roundedField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF242424),
        hintStyle: const TextStyle(color: Color(0xFF8F8F8F)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _phoneField() {
    final selectedCountry = _countries.firstWhere(
      (country) =>
          country['code'] == _selectedCountryCode &&
          country['flag'] == _selectedCountryFlag,
      orElse: () => _countries.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF171717),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, String>>(
                value: selectedCountry,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFBDBDBD),
                  size: 22,
                ),
                items: _countries.map((country) {
                  return DropdownMenuItem<Map<String, String>>(
                    value: country,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(country['flag'] ?? ''),
                        const SizedBox(width: 6),
                        Text(
                          country['code'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCountryCode = value['code'] ?? '+234';
                    _selectedCountryFlag =
                        value['flag'] ?? '\u{1F1F3}\u{1F1EC}';
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 15, color: Colors.white),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.isEmpty) return 'Phone number is required';
                if (digits.length < 7) return 'Enter a valid phone number';
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'Phone number',
                hintStyle: TextStyle(color: Color(0xFF8F8F8F), fontSize: 15),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101010),
        body: Center(
          child: CircularProgressIndicator(color: CitiRideTheme.primaryYellow),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 22,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal info',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Profile photo'),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E2E2E)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: _avatarImageProvider(),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: _chooseAvatar,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: CitiRideTheme.primaryYellow,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                'Upload photo',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _label('Name'),
                      const SizedBox(height: 10),
                      _roundedField(
                        controller: _nameController,
                        hint: 'Add your full name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _label('User name'),
                      const SizedBox(height: 10),
                      _roundedField(
                        controller: _usernameController,
                        hint: 'Choose a username',
                        validator: (value) {
                          final username = value?.trim() ?? '';
                          if (username.isEmpty) return 'Username is required';
                          if (username.length < 3) {
                            return 'At least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _label('Email'),
                      const SizedBox(height: 10),
                      _roundedField(
                        controller: _emailController,
                        hint: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );
                          return emailRegex.hasMatch(text)
                              ? null
                              : 'Enter a valid email';
                        },
                      ),
                      const SizedBox(height: 16),
                      _label('Phone number'),
                      const SizedBox(height: 10),
                      _phoneField(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Save changes',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

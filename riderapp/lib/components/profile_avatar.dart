import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.size,
    this.refreshSeed = 0,
    this.borderColor,
    this.borderWidth = 0,
    this.onTap,
  });

  final double size;
  final int refreshSeed;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _asset;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _load();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final asset = (prefs.getString('profile_avatar_asset') ?? '').trim();
    final encoded = (prefs.getString('profile_avatar_base64') ?? '').trim();
    Uint8List? bytes;

    if (encoded.isNotEmpty) {
      try {
        bytes = base64Decode(encoded);
      } catch (_) {
        bytes = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _asset = asset.isNotEmpty ? asset : 'images/profile.png';
      _bytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final avatar = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(child: _image()),
    );

    if (widget.onTap == null) return avatar;

    return GestureDetector(onTap: widget.onTap, child: avatar);
  }

  Widget _image() {
    if (_bytes != null && _bytes!.isNotEmpty) {
      return Image.memory(
        _bytes!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
      );
    }

    final asset = _asset ?? 'images/profile.png';

    return Image.asset(
      asset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.person_rounded, color: Colors.white),
    );
  }
}

import 'package:flutter/foundation.dart';

@immutable
class NigerianBank {
  const NigerianBank({
    required this.name,
    required this.code,
    required this.slug,
    this.longCode,
    this.logoUrl,
    this.ussd,
  });

  factory NigerianBank.fromPaystack(Map<String, dynamic> json) {
    final name = (json['name'] as String? ?? '').trim();
    final slug = (json['slug'] as String? ?? '').trim();
    return NigerianBank(
      name: name,
      code: (json['code'] as String? ?? '').trim(),
      slug: slug.isNotEmpty ? slug : _slugify(name),
      longCode: (json['longcode'] as String?)?.trim(),
    );
  }

  final String name;
  final String code;
  final String slug;
  final String? longCode;
  final String? logoUrl;
  final String? ussd;

  NigerianBank copyWith({String? logoUrl, String? ussd}) {
    return NigerianBank(
      name: name,
      code: code,
      slug: slug,
      longCode: longCode,
      logoUrl: logoUrl ?? this.logoUrl,
      ussd: ussd ?? this.ussd,
    );
  }

  static String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

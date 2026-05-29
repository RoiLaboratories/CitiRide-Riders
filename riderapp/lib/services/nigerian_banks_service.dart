import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nigerian_bank.dart';

class NigerianBanksService {
  NigerianBanksService({http.Client? client}) : _client = client ?? http.Client();

  static const _paystackBanksUrl =
      'https://api.paystack.co/bank?country=nigeria&currency=NGN&type=nuban';
  static const _logoDataUrl =
      'https://supermx1.github.io/nigerian-banks-api/data.json';
  static const _logoBaseUrl = 'https://supermx1.github.io/nigerian-banks-api';

  final http.Client _client;

  Future<List<NigerianBank>> fetchBanks() async {
    try {
      final banksResponse = await _client
          .get(Uri.parse(_paystackBanksUrl))
          .timeout(const Duration(seconds: 12));
      if (banksResponse.statusCode < 200 || banksResponse.statusCode >= 300) {
        return offlineBanks;
      }

      final decoded = jsonDecode(banksResponse.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is! List) return offlineBanks;

      final logoIndex = await _fetchLogoIndex();
      final banks = data
          .whereType<Map<String, dynamic>>()
          .map(NigerianBank.fromPaystack)
          .where((bank) => bank.name.isNotEmpty && bank.code.isNotEmpty)
          .map((bank) {
            final logo = logoIndex[_key(bank.code)] ?? logoIndex[_key(bank.name)];
            if (logo == null) return bank;
            return bank.copyWith(logoUrl: logo.logoUrl, ussd: logo.ussd);
          })
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return banks.isEmpty ? offlineBanks : banks;
    } catch (_) {
      return offlineBanks;
    }
  }

  Future<Map<String, _LogoRecord>> _fetchLogoIndex() async {
    try {
      final response = await _client
          .get(Uri.parse(_logoDataUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const {};
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const {};

      final index = <String, _LogoRecord>{};
      for (final item in decoded.whereType<Map<String, dynamic>>()) {
        final name = (item['name'] as String? ?? '').trim();
        final code = (item['code'] as String? ?? '').trim();
        final logo = (item['logo'] as String? ?? '').trim();
        final ussd = (item['ussd'] as String?)?.trim();
        if (name.isEmpty || logo.isEmpty) continue;

        final record = _LogoRecord(
          logoUrl: '$_logoBaseUrl/$logo',
          ussd: ussd == null || ussd.isEmpty ? null : ussd,
        );
        index[_key(name)] = record;
        if (code.isNotEmpty) index[_key(code)] = record;
      }

      return index;
    } catch (_) {
      return const {};
    }
  }

  static String _key(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static const List<NigerianBank> offlineBanks = [
    NigerianBank(
      name: 'Access Bank',
      code: '044',
      slug: 'access-bank',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/access-bank.png',
      ussd: '*901#',
    ),
    NigerianBank(
      name: 'First Bank of Nigeria',
      code: '011',
      slug: 'first-bank-of-nigeria',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/first-bank-of-nigeria.png',
      ussd: '*894#',
    ),
    NigerianBank(
      name: 'Guaranty Trust Bank',
      code: '058',
      slug: 'guaranty-trust-bank',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/guaranty-trust-bank.png',
      ussd: '*737#',
    ),
    NigerianBank(
      name: 'United Bank For Africa',
      code: '033',
      slug: 'united-bank-for-africa',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/united-bank-for-africa.png',
      ussd: '*919#',
    ),
    NigerianBank(
      name: 'Zenith Bank',
      code: '057',
      slug: 'zenith-bank',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/zenith-bank.png',
      ussd: '*966#',
    ),
    NigerianBank(
      name: 'Stanbic IBTC Bank',
      code: '221',
      slug: 'stanbic-ibtc-bank',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/stanbic-ibtc-bank.png',
    ),
    NigerianBank(
      name: 'Sterling Bank',
      code: '232',
      slug: 'sterling-bank',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/sterling-bank.png',
      ussd: '*822#',
    ),
    NigerianBank(
      name: 'Wema Bank',
      code: '035',
      slug: 'wema-bank',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/wema-bank.png',
      ussd: '*945#',
    ),
    NigerianBank(
      name: 'Titan Bank',
      code: '102',
      slug: 'titan-bank',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/titan-bank.png',
    ),
    NigerianBank(
      name: 'Moniepoint MFB',
      code: '50515',
      slug: 'moniepoint-mfb',
      logoUrl:
          'https://supermx1.github.io/nigerian-banks-api/logos/moniepoint-mfb.png',
    ),
  ];
}

class _LogoRecord {
  const _LogoRecord({required this.logoUrl, this.ussd});

  final String logoUrl;
  final String? ussd;
}

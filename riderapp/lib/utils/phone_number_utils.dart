String normalizedPhoneNumber({
  required String countryCode,
  required Iterable<String> digits,
}) {
  final cleanedCountryCode = countryCode.trim();
  final countryDigits = cleanedCountryCode.replaceAll(RegExp(r'\D'), '');
  var phoneDigits = digits.join().replaceAll(RegExp(r'\D'), '');

  if (countryDigits == '234' &&
      phoneDigits.length == 11 &&
      phoneDigits.startsWith('0')) {
    phoneDigits = phoneDigits.substring(1);
  }

  if (countryDigits.isNotEmpty && phoneDigits.startsWith(countryDigits)) {
    phoneDigits = phoneDigits.substring(countryDigits.length);
  }

  return '$cleanedCountryCode$phoneDigits';
}

bool isValidPhoneDigits({
  required String countryCode,
  required Iterable<String> digits,
}) {
  final countryDigits = countryCode.replaceAll(RegExp(r'\D'), '');
  final phoneDigits = digits.join().replaceAll(RegExp(r'\D'), '');

  if (countryDigits == '234') {
    return (phoneDigits.length == 10 && !phoneDigits.startsWith('0')) ||
        (phoneDigits.length == 11 && phoneDigits.startsWith('0'));
  }

  return phoneDigits.length == 10;
}

int maxPhoneDigitsForCountry(String countryCode) {
  final countryDigits = countryCode.replaceAll(RegExp(r'\D'), '');
  return countryDigits == '234' ? 11 : 10;
}

String phoneDigitsValidationMessage({
  required String countryCode,
  required Iterable<String> digits,
}) {
  final phoneDigits = digits.join().replaceAll(RegExp(r'\D'), '');
  if (phoneDigits.isEmpty ||
      isValidPhoneDigits(countryCode: countryCode, digits: digits)) {
    return '';
  }

  final countryDigits = countryCode.replaceAll(RegExp(r'\D'), '');
  if (countryDigits == '234') {
    return 'Enter 10 digits, or 11 digits starting with 0';
  }

  return 'Phone number should be 10 digits';
}

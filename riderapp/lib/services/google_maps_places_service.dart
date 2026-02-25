import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'google_places_web_autocomplete_stub.dart'
    if (dart.library.html) 'google_places_web_autocomplete.dart';

class GoogleMapsPlacesService {
  GoogleMapsPlacesService({http.Client? client})
    : _client = client ?? http.Client();

  static const String _mapsApiKey = 'AIzaSyActFrssaaKA5CUikTsI8_98RukSoPXBTY';
  final http.Client _client;

  Future<List<Map<String, String>>> autocompletePlaces(String input) async {
    final query = input.trim();
    if (query.isEmpty) return const [];

    if (kIsWeb) {
      final jsSuggestions = await fetchGoogleWebPlaceSuggestions(query);
      if (jsSuggestions.isNotEmpty) {
        return jsSuggestions;
      }
    }

    return _autocompletePlacesWebService(query);
  }

  Future<List<Map<String, String>>> _autocompletePlacesWebService(
    String query,
  ) async {
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': query,
          'key': _mapsApiKey,
          'language': 'en',
          'types': 'geocode',
        },
      );

      final response = await _client.get(uri);
      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (decoded['status'] as String?) ?? '';
      if (status != 'OK' && status != 'ZERO_RESULTS') return const [];

      final predictions = (decoded['predictions'] as List?) ?? const [];

      return predictions.take(8).map((entry) {
        final prediction = entry as Map<String, dynamic>;
        final structured =
            (prediction['structured_formatting'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
        final description = (prediction['description'] as String?) ?? '';
        final mainText = (structured['main_text'] as String?) ?? description;
        final secondaryText = (structured['secondary_text'] as String?) ?? '';
        final placeId = (prediction['place_id'] as String?) ?? '';

        return <String, String>{
          'name': mainText,
          'subtitle': secondaryText,
          'value': description,
          'placeId': placeId,
        };
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String?> reverseGeocodeAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '$latitude,$longitude',
        'key': _mapsApiKey,
        'language': 'en',
      });

      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (decoded['status'] as String?) ?? '';
      if (status != 'OK') return null;

      final results = (decoded['results'] as List?) ?? const [];
      if (results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final formatted = (first['formatted_address'] as String?)?.trim() ?? '';
      return formatted.isEmpty ? null : formatted;
    } catch (_) {
      return null;
    }
  }
}

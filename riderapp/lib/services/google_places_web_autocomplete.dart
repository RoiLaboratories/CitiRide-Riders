import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

String _readStringProperty(JSObject object, String key) {
  final value = object[key];
  if (value is JSString) return value.toDart;
  return '';
}

JSObject _newJsObject() {
  final objectConstructor = globalContext['Object'];
  if (objectConstructor is! JSFunction) {
    throw StateError('JavaScript Object constructor unavailable.');
  }
  return objectConstructor.callAsConstructor<JSObject>();
}

Future<List<Map<String, String>>> fetchGoogleWebPlaceSuggestions(
  String query,
) async {
  final cleaned = query.trim();
  if (cleaned.isEmpty) return const [];

  try {
    final google = globalContext['google'];
    if (google is! JSObject) return const [];
    final maps = google['maps'];
    if (maps is! JSObject) return const [];
    final places = maps['places'];
    if (places is! JSObject) return const [];
    final serviceConstructor = places['AutocompleteService'];
    if (serviceConstructor is! JSFunction) return const [];

    final service = serviceConstructor.callAsConstructor<JSObject>();
    final completer = Completer<List<Map<String, String>>>();

    final request = _newJsObject();
    request['input'] = cleaned.toJS;
    request['types'] = <JSString>['geocode'.toJS].toJS;

    void onPredictions(JSAny? predictions, JSAny? status) {
        if (completer.isCompleted) return;

        final statusText = status is JSString ? status.toDart : '';
        if (statusText != 'OK' && statusText != 'ZERO_RESULTS') {
          completer.complete(const []);
          return;
        }

        if (statusText == 'ZERO_RESULTS' || predictions == null) {
          completer.complete(const []);
          return;
        }

        if (predictions is! JSArray<JSAny?>) {
          completer.complete(const []);
          return;
        }

        final rawPredictions = predictions.toDart;
        final mapped = <Map<String, String>>[];
        for (final item in rawPredictions) {
          if (item is! JSObject) continue;
          final description = _readStringProperty(item, 'description').trim();

          final structuredAny = item['structured_formatting'];
          final structured = structuredAny is JSObject ? structuredAny : null;
          final mainText = structured == null
              ? ''
              : _readStringProperty(structured, 'main_text').trim();
          final secondaryText = structured == null
              ? ''
              : _readStringProperty(structured, 'secondary_text').trim();
          final placeId = _readStringProperty(item, 'place_id').trim();

          final value = description.isNotEmpty
              ? description
              : [mainText, secondaryText]
                    .where((part) => part.isNotEmpty)
                    .join(', ');
          if (value.isEmpty) continue;

          mapped.add(<String, String>{
            'name': mainText.isNotEmpty ? mainText : value,
            'subtitle': secondaryText,
            'value': value,
            'placeId': placeId,
          });
        }

        completer.complete(mapped.take(8).toList());
      }

    service.callMethodVarArgs<JSAny?>(
      'getPlacePredictions'.toJS,
      <JSAny?>[request, onPredictions.toJS],
    );

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => const [],
    );
  } catch (_) {
    return const [];
  }
}

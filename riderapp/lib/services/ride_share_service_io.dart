import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const MethodChannel _shareChannel = MethodChannel('citiride/share');

Future<bool> shareRideScreenshotImpl(Uint8List pngBytes, String text) async {
  final directory = await getTemporaryDirectory();
  final file = File(
    '${directory.path}/citiride_ride_${DateTime.now().millisecondsSinceEpoch}.png',
  );

  await file.writeAsBytes(pngBytes, flush: true);

  final shared = await _shareChannel.invokeMethod<bool>('shareImage', {
    'path': file.path,
    'text': text,
  });

  return shared ?? false;
}

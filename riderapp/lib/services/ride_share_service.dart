import 'dart:typed_data';

import 'ride_share_service_stub.dart'
    if (dart.library.io) 'ride_share_service_io.dart';

Future<bool> shareRideScreenshot(Uint8List pngBytes, String text) {
  return shareRideScreenshotImpl(pngBytes, text);
}

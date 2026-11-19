import 'package:flutter/foundation.dart';

class AppPlatform {
  static bool get web => kIsWeb;

  static bool get mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get native => !kIsWeb;
}

import 'package:flutter/foundation.dart';

class AppPlatform {
  static bool get mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

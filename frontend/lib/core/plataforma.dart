import 'package:flutter/foundation.dart';

class Plataforma {
  static bool get mobile => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

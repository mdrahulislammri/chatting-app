import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://localhost:8000/api/v1';
    }
  }

  static String get reverbHost {
    if (kIsWeb) {
      return 'localhost';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    } else {
      return 'localhost';
    }
  }

  static const String reverbAppKey = 'xj1n6kg4wcidxmqxwt1b';
  static const int reverbPort = 8080;
}

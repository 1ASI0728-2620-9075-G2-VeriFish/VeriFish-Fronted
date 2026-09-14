import 'package:flutter/foundation.dart';
import 'dart:io';

class Environment {
  static String get baseUrl {
    // Pass --dart-define=API_BASE_URL=... at build time to override (used for prod deploys).
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) {
      // Si es Chrome local (flutter run), usa localhost
      return 'http://localhost:8080/api';
    } else if (Platform.isAndroid) {
      // Si es Android, usa su túnel
      return 'http://10.0.2.2:8080/api';
    } else {
      return 'http://localhost:8080/api';
    }
  }
}
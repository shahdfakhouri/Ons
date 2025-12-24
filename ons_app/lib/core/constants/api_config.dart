import 'package:flutter/foundation.dart';

class ApiConfig {
  // ✅ if you run on Android emulator => use 10.0.2.2
  // ✅ web/desktop => localhost works
  static const String _androidEmulatorHost = 'http://10.0.2.2:5000';
  static const String _localHost = 'http://localhost:5000';

  static String get baseUrl => kIsWeb ? _localHost : _androidEmulatorHost;

  static String get authBase => '$baseUrl/api/auth';
  static String get adminBase => '$baseUrl/api/admin';
}

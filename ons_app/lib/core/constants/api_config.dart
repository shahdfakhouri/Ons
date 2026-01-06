import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _androidEmulatorHost = 'http://10.0.2.2:5000';
  static const String _localHost = 'http://localhost:5000';

  static String get baseUrl => kIsWeb ? _localHost : _androidEmulatorHost;

  static String get authBase => '$baseUrl/api/auth';
  static String get adminBase => '$baseUrl/api/admin';
  static String get caregiverBase => '$baseUrl/api/caregiver';
  static String get retirementBase => '$baseUrl/api/retirement';
}

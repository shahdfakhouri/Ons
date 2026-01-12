import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _androidEmulatorHost = 'http://10.0.2.2:5000';
  static const String _localHost = 'http://localhost:5000';

  static String get baseUrl => kIsWeb ? _localHost : _androidEmulatorHost;

  // ✅ add this
  static String get apiBase => '$baseUrl/api';

  // existing
  static String get authBase => '$baseUrl/api/auth';
  static String get adminBase => '$baseUrl/api/admin';
  static String get caregiverBase => '$baseUrl/api/caregiver';
  static String get retirementBase => '$baseUrl/api/retirement';

  // ✅ add these for Family + Notifications
  static String get familyBase => '$baseUrl/api/family';
static String get notificationsBase => '$baseUrl/api/notifications';

static String get elderBase => '$baseUrl/api/elder';
static String get communityBase => '$baseUrl/api/community';
static String get companionBase => '$baseUrl/api/companion';
static String get entertainmentBase => '$baseUrl/api/entertainment';



  
}

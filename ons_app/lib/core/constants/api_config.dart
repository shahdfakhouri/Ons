import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _androidEmulatorHost = 'http://10.0.2.2:5000';
  static const String _localHost = 'http://localhost:5000';

  // ✅ Correct:
  // - Web + Windows + macOS + Linux => localhost
  // - Android emulator => 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) return _localHost;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidEmulatorHost;
      default:
        return _localHost;
    }
  }

  static String get apiBase => '$baseUrl/api';

  static String get authBase => '$baseUrl/api/auth';
  static String get adminBase => '$baseUrl/api/admin';
  static String get caregiverBase => '$baseUrl/api/caregiver';
  static String get retirementBase => '$baseUrl/api/retirement';

  static String get familyBase => '$baseUrl/api/family';
  static String get notificationsBase => '$baseUrl/api/notifications';

  static String get elderBase => '$baseUrl/api/elder';
  static String get communityBase => '$baseUrl/api/community';
  static String get companionBase => '$baseUrl/api/companion';
  static String get entertainmentBase => '$baseUrl/api/entertainment';
  static String get medicationBase => '$baseUrl/api/medication';
  static String get retirementReportsBase => '$baseUrl/api/retirement/reports';
  static String get retirementNotesBase => '$baseUrl/api/retirement/notes';
  static String get paymentsBase => '$baseUrl/api/payments';
  static String get transactionsBase => '$baseUrl/api/transactions';

  static String get chatH2HBase => '$baseUrl/api/chat-h2h';
}

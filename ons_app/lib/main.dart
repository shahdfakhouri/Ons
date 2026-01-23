import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ons_app/core/theme/app_theme.dart';

// screens
import 'package:ons_app/screens/home/home_page.dart';
import 'package:ons_app/screens/auth/login_page.dart';
import 'package:ons_app/screens/admin/admin_dashboard.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/screens/family/family_layout.dart';
import 'package:ons_app/screens/elder/elder_layout.dart';
import 'package:ons_app/screens/elder/pages/elder_pin_login_page.dart';

// services
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/services/elder_auth_service.dart';

// firebase (only used on mobile)
import 'package:firebase_core/firebase_core.dart';
import 'package:ons_app/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase + FCM only on Android/iOS (skip on Web/Chrome)
  if (!kIsWeb) {
    await Firebase.initializeApp();
    await FcmService.init(); // prints FCM token (on Android)
  }

  await AuthService().loadSession();
  await ElderAuthService().loadSession();

  runApp(const OnsApp());
}

class OnsApp extends StatelessWidget {
  const OnsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ons',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomePage(),
        '/login': (_) => const LoginPage(),
        '/admin/dashboard': (_) => const AdminDashboardPage(),
        '/caregiver/dashboard': (_) => const CaregiverLayout(),
        '/retirement/dashboard': (_) => const RetirementHomeLayout(),
        '/family/dashboard': (_) => const FamilyLayout(),
        '/elder/login': (_) => const ElderLoginPage(),
        '/elder/dashboard': (_) => const ElderLayout(),
      },
    );
  }
}

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';

// screens
import 'package:ons_app/screens/home/home_page.dart';
import 'package:ons_app/screens/auth/login_page.dart';
import 'package:ons_app/screens/admin/admin_dashboard.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/screens/family/family_layout.dart';
import 'package:ons_app/screens/elder/elder_layout.dart';


// services
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/services/elder_auth_service.dart';

// elder pages (YOUR STRUCTURE)
import 'package:ons_app/screens/elder/pages/elder_pin_login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService().loadSession();       // normal users token
  await ElderAuthService().loadSession();  // elder token

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

        // dashboards by role
        '/admin/dashboard': (_) => const AdminDashboardPage(),
        '/caregiver/dashboard': (_) => const CaregiverLayout(),
        '/retirement/dashboard': (_) => const RetirementHomeLayout(),
        '/family/dashboard': (_) => const FamilyLayout(),

        // ✅ Elder (separate flow, no UserRole needed)
        '/elder/login': (_) => const ElderLoginPage(),
        '/elder/dashboard': (_) => const ElderLayout(),
}

    );
  }
}

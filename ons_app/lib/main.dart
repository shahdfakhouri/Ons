// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';

// screens
import 'package:ons_app/screens/home/home_page.dart';
import 'package:ons_app/screens/auth/login_page.dart';
import 'package:ons_app/screens/admin/admin_dashboard.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';

void main() {
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

      // 🧭 initial screen
      initialRoute: '/home',

      // 🗺️ named routes
      routes: {
        '/home': (_) => const HomePage(),
        '/login': (_) => const LoginPage(),

        // dashboards by role
       ///admin/dashboard': (_) => const AdminDashboardPage(),
       ///caregiver/dashboard': (_) => const CaregiverLayout(), 

        // later you can add:
        // '/family/dashboard': (_) => const FamilyDashboardPage(),
        // '/home/dashboard': (_) => const RetirementHomeDashboardPage(),
      },
    );
  }
}

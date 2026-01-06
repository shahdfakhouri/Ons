// lib/screens/auth/role_navigator.dart
import 'package:flutter/material.dart';
import 'package:ons_app/models/user.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/screens/admin/admin_dashboard.dart';

void navigateToRoleHome(BuildContext context, User user) {
  Widget destination;

  switch (user.role) {
    case UserRole.family:
      destination = Scaffold(
        appBar: AppBar(title: const Text('Family Dashboard')),
        body: const Center(child: Text('Family dashboard coming soon')),
      );
      break;
    case UserRole.caregiver:
      destination = const CaregiverLayout();
      break;
    case UserRole.retirementHome:
      destination = const RetirementHomeLayout();
      break;
    case UserRole.admin:
      destination = const AdminDashboardPage();
      break;
  }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => destination),
  );
}

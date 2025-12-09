// lib/screens/auth/role_navigator.dart
import 'package:flutter/material.dart';
import 'package:ons_app/models/user.dart';
import 'package:ons_app/screens/family/family_dashboard.dart';
import 'package:ons_app/screens/caregiver/caregiver_dashboard.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_dashboard.dart';
import 'package:ons_app/screens/admin/admin_dashboard.dart';

void navigateToRoleHome(BuildContext context, User user) {
  Widget destination;

  switch (user.role) {
    case UserRole.family:
      destination = const FamilyDashboardPage();
      break;
    case UserRole.caregiver:
      destination = const CaregiverDashboardPage();

      break;
    case UserRole.retirementHome:
      destination = const RetirementHomeDashboardPage();
      break;
    case UserRole.admin:
      destination = const AdminDashboardPage();
      break;
  }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => destination),
  );
}

import 'package:flutter/material.dart';
import 'package:ons_app/models/user.dart';

import 'package:ons_app/screens/family/family_layout.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/screens/admin/admin_dashboard.dart';

void navigateToRoleHome(BuildContext context, User user) {
  Widget destination;

  switch (user.role) {
    case UserRole.family:
      destination = const FamilyLayout();
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

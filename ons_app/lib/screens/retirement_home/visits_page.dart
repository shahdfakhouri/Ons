import 'package:flutter/material.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';

class VisitsPage extends StatelessWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RetirementHomeLayout(
      title: 'Visits',
      child: Center(
        child: Text('Visits module is not mounted in /api/retirement yet.\nAdd routes then we will connect it.'),
      ),
    );
  }
}

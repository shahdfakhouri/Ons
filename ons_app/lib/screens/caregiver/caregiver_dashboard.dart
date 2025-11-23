import 'package:flutter/material.dart';

class CaregiverDashboardPage extends StatelessWidget {
  const CaregiverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Dashboard"),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: Center(
        child: Text(
          "Caregiver Dashboard (placeholder)",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

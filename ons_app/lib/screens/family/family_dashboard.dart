import 'package:flutter/material.dart';

class FamilyDashboardPage extends StatelessWidget {
  const FamilyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Family Dashboard"),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: Center(
        child: Text(
          "Family Dashboard (placeholder)",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

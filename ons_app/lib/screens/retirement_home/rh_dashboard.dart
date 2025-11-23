import 'package:flutter/material.dart';

class RhDashboardPage extends StatelessWidget {
  const RhDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Retirement Home Dashboard"),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: Center(
        child: Text(
          "Retirement Home Dashboard (placeholder)",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';

class HealthLogsPage extends StatelessWidget {
  const HealthLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Health Logs',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HealthLogCard(
            elderName: 'Abu Ahmad',
            summary: 'BP: 130/80, mood: good, visit completed.',
          ),
          _HealthLogCard(
            elderName: 'Um Omar',
            summary: 'Slight fever reported, doctor notified.',
          ),
        ],
      ),
    );
  }
}

class _HealthLogCard extends StatelessWidget {
  final String elderName;
  final String summary;

  const _HealthLogCard({
    super.key,
    required this.elderName,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              elderName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              summary,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurface.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

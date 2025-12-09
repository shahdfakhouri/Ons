import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';

class CaregiverHealthLogsPage extends StatelessWidget {
  const CaregiverHealthLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final logs = [
      HealthLog(
        elderName: 'Um Ahmad',
        date: 'Today',
        summary: 'Calm, BP normal, took medication, walked 10 minutes.',
      ),
      HealthLog(
        elderName: 'Abu Youssef',
        date: 'Yesterday',
        summary:
            'Complained of mild knee pain, recommended extra rest and ice.',
      ),
      HealthLog(
        elderName: 'Hajja Fatima',
        date: '2 days ago',
        summary: 'Post-surgery wound looks clean, pain level 3/10.',
      ),
    ];

    return CaregiverLayout(
      title: 'Health logs',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                // later: open "Add health log" form
              },
              icon: const Icon(Icons.add),
              label: const Text('Add health log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.denim,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colors.onSurface.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log.elderName} • ${log.date}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.deepNavy,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        log.summary,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: colors.onSurface.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HealthLog {
  final String elderName;
  final String date;
  final String summary;

  HealthLog({
    required this.elderName,
    required this.date,
    required this.summary,
  });
}

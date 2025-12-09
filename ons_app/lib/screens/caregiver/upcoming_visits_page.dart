import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';

class UpcomingVisitsPage extends StatelessWidget {
  const UpcomingVisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final visits = [
      VisitItem(
        elderName: 'Um Ahmad',
        location: 'Nablus, Al-Makhfiya',
        date: 'Today',
        timeRange: '16:00 – 18:00',
        type: 'Companionship & medication',
      ),
      VisitItem(
        elderName: 'Abu Youssef',
        location: 'Retirement Home – Ramallah',
        date: 'Tomorrow',
        timeRange: '10:00 – 12:00',
        type: 'Mobility assistance',
      ),
      VisitItem(
        elderName: 'Hajja Fatima',
        location: 'Hebron, Ein Sara',
        date: 'Friday',
        timeRange: '09:00 – 11:00',
        type: 'Post-surgery follow-up',
      ),
    ];

    return CaregiverLayout(
      title: 'Upcoming visits',
      child: ListView.separated(
        itemCount: visits.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final v = visits[index];
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
                  v.elderName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepNavy,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${v.date} • ${v.timeRange}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  v.location,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  v.type,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class VisitItem {
  final String elderName;
  final String location;
  final String date;
  final String timeRange;
  final String type;

  VisitItem({
    required this.elderName,
    required this.location,
    required this.date,
    required this.timeRange,
    required this.type,
  });
}

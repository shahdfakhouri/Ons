import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';

class CareRequestsPage extends StatelessWidget {
  const CareRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final requests = [
      CareRequestItem(
        id: 'req1',
        elderName: 'Um Ahmad',
        need: 'Evening companionship & medication',
        schedule: 'Daily • 16:00 – 18:00',
        status: 'Open',
      ),
      CareRequestItem(
        id: 'req2',
        elderName: 'Abu Youssef',
        need: 'Mobility support after physiotherapy',
        schedule: 'Mon, Wed • 10:00 – 12:00',
        status: 'Matched',
      ),
      CareRequestItem(
        id: 'req3',
        elderName: 'Hajja Fatima',
        need: 'Post-surgery follow-up',
        schedule: 'Fri • 09:00 – 11:00',
        status: 'Pending admin approval',
      ),
    ];

    return RetirementHomeLayout(
      title: 'Care requests',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                // later: open "Create request" form
              },
              icon: const Icon(Icons.add),
              label: const Text('New care request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.denim,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = requests[index];
                final color = _statusColor(r.status, colors);
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
                        r.elderName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepNavy,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.need,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: colors.onSurface.withOpacity(0.8),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.schedule,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: colors.onSurface.withOpacity(0.7),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          r.status,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
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

  Color _statusColor(String status, ColorScheme colors) {
    if (status == 'Open') return Colors.orange;
    if (status == 'Matched') return Colors.green;
    return colors.onSurface.withOpacity(0.8);
  }
}

class CareRequestItem {
  final String id;
  final String elderName;
  final String need;
  final String schedule;
  final String status;

  CareRequestItem({
    required this.id,
    required this.elderName,
    required this.need,
    required this.schedule,
    required this.status,
  });
}

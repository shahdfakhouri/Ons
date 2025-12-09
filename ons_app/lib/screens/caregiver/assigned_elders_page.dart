import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';

class AssignedEldersPage extends StatelessWidget {
  const AssignedEldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final elders = [
      AssignedElder(
        name: 'Um Ahmad',
        age: 78,
        livingType: 'Home',
        location: 'Nablus, Al-Makhfiya',
        mainNeeds: 'Companionship, medication reminders',
      ),
      AssignedElder(
        name: 'Abu Youssef',
        age: 82,
        livingType: 'Retirement home',
        location: 'Retirement Home – Ramallah',
        mainNeeds: 'Mobility support, fall risk',
      ),
      AssignedElder(
        name: 'Hajja Fatima',
        age: 74,
        livingType: 'Home',
        location: 'Hebron, Ein Sara',
        mainNeeds: 'Post-surgery follow-up',
      ),
    ];

    return CaregiverLayout(
      title: 'Assigned elders',
      child: ListView.separated(
        itemCount: elders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final e = elders[index];
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.sage.withOpacity(0.4),
                  child: Text(
                    e.name[0],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.deepNavy,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
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
                        '${e.age} years • ${e.livingType}',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.location,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.mainNeeds,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withOpacity(0.9),
                                ),
                      ),
                    ],
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

class AssignedElder {
  final String name;
  final int age;
  final String livingType;
  final String location;
  final String mainNeeds;

  AssignedElder({
    required this.name,
    required this.age,
    required this.livingType,
    required this.location,
    required this.mainNeeds,
  });
}

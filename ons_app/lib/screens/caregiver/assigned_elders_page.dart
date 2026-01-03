import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/services/dio_factory.dart';
import 'package:ons_app/services/caregiver_api.dart';
import 'package:ons_app/screens/caregiver/elder_detail_page.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';

class AssignedEldersPage extends StatefulWidget {
  const AssignedEldersPage({super.key});

  @override
  State<AssignedEldersPage> createState() => _AssignedEldersPageState();
}

class _AssignedEldersPageState extends State<AssignedEldersPage> {
  late final CaregiverApi api;
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    api = CaregiverApi(DioFactory.create());
    future = api.getAssignedElders();
  }

  Future<void> _refresh() async {
    setState(() => future = api.getAssignedElders());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CaregiverLayout(
      title: 'Assigned elders',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                'Failed to load elders.\n${snap.error}',
                style: TextStyle(color: colors.error),
                textAlign: TextAlign.center,
              ),
            );
          }

          final elders = snap.data ?? [];
          if (elders.isEmpty) {
            return Center(
              child: Text(
                'No assigned elders yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.deepNavy.withOpacity(0.7),
                    ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: elders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = elders[i];
                final elderId = e['elder_id'];
                final name = (e['name'] ?? 'Unknown').toString();
                final gender = (e['gender'] ?? '').toString();
                final age = (e['age'] ?? '').toString();
                final lastCheck = e['last_check_in']?.toString();

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ElderDetailPage(elderId: elderId),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colors.onSurface.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.sage.withOpacity(0.35),
                          child: Icon(Icons.person, color: AppTheme.denim),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.deepNavy,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Age: $age  •  $gender',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.deepNavy.withOpacity(0.7),
                                    ),
                              ),
                              if (lastCheck != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Last check-in: $lastCheck',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.deepNavy.withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

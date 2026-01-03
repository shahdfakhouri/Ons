import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/services/caregiver_api.dart';
import 'package:ons_app/services/dio_factory.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';

class ElderDetailPage extends StatefulWidget {
  final int elderId;
  const ElderDetailPage({super.key, required this.elderId});

  @override
  State<ElderDetailPage> createState() => _ElderDetailPageState();
}

class _ElderDetailPageState extends State<ElderDetailPage> {
  late final CaregiverApi api;

  late Future<Map<String, dynamic>> elderFuture;
  late Future<Map<String, dynamic>> statusFuture;
  late Future<List<Map<String, dynamic>>> alertsFuture;

  @override
  void initState() {
    super.initState();
    api = CaregiverApi(DioFactory.create());
    elderFuture = api.getElderDetails(widget.elderId);
    statusFuture = api.getElderStatus(widget.elderId);
    alertsFuture = api.getElderAlerts(widget.elderId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CaregiverLayout(
      title: 'Elder details',
      child: FutureBuilder<Map<String, dynamic>>(
        future: elderFuture,
        builder: (context, elderSnap) {
          if (elderSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (elderSnap.hasError) {
            return Center(
              child: Text(
                'Failed to load elder.\n${elderSnap.error}',
                style: TextStyle(color: colors.error),
                textAlign: TextAlign.center,
              ),
            );
          }

          final elder = elderSnap.data ?? {};
          final name = (elder['name'] ?? 'Unknown').toString();

          return ListView(
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepNavy,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Age: ${elder['age'] ?? '-'} • ${elder['gender'] ?? '-'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.deepNavy.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 18),

              // Status card
              FutureBuilder<Map<String, dynamic>>(
                future: statusFuture,
                builder: (context, s) {
                  if (!s.hasData) return const SizedBox();
                  final status = s.data?['status'] ?? {};
                  return _InfoCard(
                    title: 'Status',
                    child: Text(
                      'Last check-in: ${status['last_checkin_time'] ?? '—'}\n'
                      'Recent (8h): ${status['is_recent_checkin'] == true ? 'Yes' : 'No'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Alerts preview
              FutureBuilder<List<Map<String, dynamic>>>(
                future: alertsFuture,
                builder: (context, a) {
                  if (a.connectionState == ConnectionState.waiting) {
                    return const _InfoCard(title: 'Open alerts', child: Text('Loading...'));
                  }
                  final alerts = a.data ?? [];
                  return _InfoCard(
                    title: 'Open alerts (${alerts.length})',
                    child: alerts.isEmpty
                        ? const Text('No open alerts 🎉')
                        : Column(
                            children: alerts.take(3).map((al) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.warning_amber_rounded),
                                title: Text((al['message'] ?? '').toString()),
                                subtitle: Text('Severity: ${al['severity'] ?? '-'}'),
                              );
                            }).toList(),
                          ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Quick actions (just wiring)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      await api.checkIn(widget.elderId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Check-in saved ✅')),
                      );
                      setState(() {
                        statusFuture = api.getElderStatus(widget.elderId);
                      });
                    },
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('Check-in'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Dummy location for now (we’ll connect GPS later)
                      await api.updateLocation(widget.elderId, latitude: 32.2211, longitude: 35.2544);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location saved ✅')),
                      );
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Send location'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

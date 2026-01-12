import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  String _fmt(dynamic v) {
    try {
      return DateFormat('yyyy-MM-dd  HH:mm').format(DateTime.parse(v.toString()));
    } catch (_) {
      return v?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder(
        future: api.getAlertsAll(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final alerts = (data['alerts'] as List?) ?? const [];

          if (alerts.isEmpty) {
            return const EmptyState(title: 'No alerts yet ✅', subtitle: 'Incidents and emergencies will appear here.');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = alerts[i] as Map;
              final type = (a['alert_type'] ?? '').toString();
              final title = (a['title'] ?? a['type'] ?? 'Alert').toString();
              final status = (a['status'] ?? '').toString();
              final severity = (a['severity'] ?? '').toString();
              final elderId = (a['elder_id'] ?? '').toString();
              final when = _fmt(a['created_at']);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(type == 'emergency' ? Icons.sos : Icons.report)),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Elder: $elderId')),
                        Chip(label: Text('Status: $status')),
                        Chip(label: Text('Severity: $severity')),
                        Chip(label: Text(when)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

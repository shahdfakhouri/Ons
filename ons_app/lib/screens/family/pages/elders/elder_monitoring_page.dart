import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class ElderMonitoringPage extends StatefulWidget {
  final int elderId;
  const ElderMonitoringPage({super.key, required this.elderId});

  @override
  State<ElderMonitoringPage> createState() => _ElderMonitoringPageState();
}

class _ElderMonitoringPageState extends State<ElderMonitoringPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  final from = TextEditingController(text: '2000-01-01');
  final to = TextEditingController(text: '2100-01-01');

  @override
  void dispose() {
    from.dispose();
    to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elderId = widget.elderId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Elder'),
              subtitle: Text('ID: $elderId'),
            ),
          ),
          const SizedBox(height: 10),
          const SectionTitle('Medication stats'),
          Row(
            children: [
              Expanded(child: AppTextField(controller: from, label: 'from (YYYY-MM-DD)')),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: to, label: 'to (YYYY-MM-DD)')),
            ],
          ),
          const SizedBox(height: 10),

          FutureBuilder(
            future: api.getMedicationStats(elderId, from: from.text.trim(), to: to.text.trim()),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final stats = (data['stats'] as Map?) ?? {};

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Chip(label: Text("Taken: ${stats['taken'] ?? 0}")),
                      Chip(label: Text("Missed: ${stats['missed'] ?? 0}")),
                      Chip(label: Text("Skipped: ${stats['skipped'] ?? 0}")),
                      Chip(label: Text("Total: ${stats['total'] ?? 0}")),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),
          const SectionTitle('Health logs'),
          _SimpleList(
            future: api.getHealthLogs(elderId),
            listKey: 'health_logs',
            titleBuilder: (m) => (m['type'] ?? m['title'] ?? 'Health log').toString(),
            subtitleBuilder: (m) => (m['date'] ?? m['created_at'] ?? '').toString(),
          ),

          const SizedBox(height: 14),
          const SectionTitle('Medications'),
          _SimpleList(
            future: api.getMedications(elderId),
            listKey: 'medications',
            titleBuilder: (m) => (m['name'] ?? 'Medication').toString(),
            subtitleBuilder: (m) => 'Dosage: ${m['dosage'] ?? '-'} • Freq: ${m['frequency'] ?? '-'} • Active: ${m['active'] ?? '-'}',
          ),

          const SizedBox(height: 14),
          const SectionTitle('Medication logs'),
          _SimpleList(
            future: api.getMedicationLogs(elderId),
            listKey: 'medication_logs',
            titleBuilder: (m) => (m['medication_name'] ?? 'Medication').toString(),
            subtitleBuilder: (m) => 'Status: ${m['status'] ?? '-'} • ${m['created_at'] ?? ''}',
          ),
        ],
      ),
    );
  }
}

class _SimpleList extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final String listKey;
  final String Function(Map m) titleBuilder;
  final String Function(Map m) subtitleBuilder;

  const _SimpleList({
    required this.future,
    required this.listKey,
    required this.titleBuilder,
    required this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
        }
        if (snap.hasError) {
          return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));
        }
        final data = (snap.data as Map<String, dynamic>? ?? {});
        final list = (data[listKey] as List?) ?? const [];

        if (list.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No data yet.')));
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = list[i] as Map;
              return ListTile(
                title: Text(titleBuilder(m), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(subtitleBuilder(m)),
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class ElderVisitsPage extends StatefulWidget {
  final int elderId;
  const ElderVisitsPage({super.key, required this.elderId});

  @override
  State<ElderVisitsPage> createState() => _ElderVisitsPageState();
}

class _ElderVisitsPageState extends State<ElderVisitsPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  final scheduledAt = TextEditingController(text: '2026-01-12 10:00:00');
  final duration = TextEditingController(text: '60');
  final notes = TextEditingController();

  @override
  void dispose() {
    scheduledAt.dispose();
    duration.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    try {
      await api.requestVisit(widget.elderId, {
        'scheduled_at': scheduledAt.text.trim(),
        'duration_minutes': int.tryParse(duration.text.trim()) ?? 60,
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, 'Visit request sent ✅');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elderId = widget.elderId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visits'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SectionTitle('Request a visit'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  AppTextField(controller: scheduledAt, label: 'scheduled_at (YYYY-MM-DD HH:MM:SS)'),
                  const SizedBox(height: 10),
                  AppTextField(controller: duration, label: 'duration_minutes', keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  AppTextField(controller: notes, label: 'notes (optional)', maxLines: 2),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _request, child: const Text('Send request')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Elder visits'),
          FutureBuilder(
            future: api.getElderVisits(elderId),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final visits = (data['visits'] as List?) ?? const [];

              if (visits.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No visits yet.')));

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final v = visits[i] as Map;
                    return ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text('Scheduled: ${v['scheduled_at'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Status: ${v['status'] ?? ''} • Notes: ${v['notes'] ?? v['reason'] ?? ''}'),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

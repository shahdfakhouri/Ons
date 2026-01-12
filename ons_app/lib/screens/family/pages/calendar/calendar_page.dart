import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  final from = TextEditingController(text: '2000-01-01 00:00:00');
  final to = TextEditingController(text: '2100-01-01 00:00:00');
  final elderId = TextEditingController();

  @override
  void dispose() {
    from.dispose();
    to.dispose();
    elderId.dispose();
    super.dispose();
  }

  String _day(dynamic dt) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(dt.toString()));
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SectionTitle('Filters'),
          Row(
            children: [
              Expanded(child: AppTextField(controller: from, label: 'from')),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: to, label: 'to')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: AppTextField(controller: elderId, label: 'elder_id (optional)', keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _reload, child: const Text('Load')),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder(
            future: api.getCalendar(
              from: from.text.trim(),
              to: to.text.trim(),
              elderId: elderId.text.trim().isEmpty ? null : elderId.text.trim(),
            ),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final list = (data['calendar'] as List?) ?? const [];

              if (list.isEmpty) {
                return const EmptyState(title: 'No items', subtitle: 'Try a wider date range.');
              }

              // group by day
              final Map<String, List<Map>> grouped = {};
              for (final it in list) {
                final m = it as Map;
                final d = _day(m['start_time']);
                grouped.putIfAbsent(d, () => []).add(m);
              }

              final days = grouped.keys.toList()..sort();

              return Column(
                children: [
                  for (final d in days) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(d, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 6),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: grouped[d]!.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final m = grouped[d]![i];
                          final type = (m['item_type'] ?? m['event_type'] ?? 'item').toString();
                          final title = (m['title'] ?? type).toString();
                          final start = (m['start_time'] ?? '').toString();
                          return ListTile(
                            leading: Icon(type == 'visit' ? Icons.calendar_month : Icons.event),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('Start: $start • Elder: ${m['elder_id'] ?? ''}'),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

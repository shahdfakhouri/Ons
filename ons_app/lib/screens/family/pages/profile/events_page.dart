import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  Future<void> _openEventForm({Map? existing}) async {
    final elderId = TextEditingController(text: existing?['elder_id']?.toString() ?? '');
    final title = TextEditingController(text: (existing?['title'] ?? '').toString());
    final desc = TextEditingController(text: (existing?['description'] ?? '').toString());
    final type = TextEditingController(text: (existing?['event_type'] ?? 'family_event').toString());
    final start = TextEditingController(text: (existing?['start_time'] ?? '2026-01-12 10:00:00').toString());
    final end = TextEditingController(text: (existing?['end_time'] ?? '').toString());
    bool allDay = (existing?['is_all_day']?.toString() ?? '0') == '1';
    final location = TextEditingController(text: (existing?['location'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Create event' : 'Update event'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              AppTextField(controller: elderId, label: 'elder_id (optional)', keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              AppTextField(controller: title, label: 'title'),
              const SizedBox(height: 10),
              AppTextField(controller: desc, label: 'description (optional)', maxLines: 2),
              const SizedBox(height: 10),
              AppTextField(controller: type, label: 'event_type (birthday/family_event/appointment/...)'),
              const SizedBox(height: 10),
              AppTextField(controller: start, label: 'start_time (YYYY-MM-DD HH:MM:SS)'),
              const SizedBox(height: 10),
              AppTextField(controller: end, label: 'end_time (optional)'),
              const SizedBox(height: 8),
              SwitchListTile(value: allDay, onChanged: (v) => allDay = v, title: const Text('All day')),
              AppTextField(controller: location, label: 'location (optional)'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    final body = {
      'elder_id': int.tryParse(elderId.text.trim()),
      'title': title.text.trim(),
      'description': desc.text.trim().isEmpty ? null : desc.text.trim(),
      'event_type': type.text.trim(),
      'start_time': start.text.trim(),
      'end_time': end.text.trim().isEmpty ? null : end.text.trim(),
      'is_all_day': allDay,
      'location': location.text.trim().isEmpty ? null : location.text.trim(),
    };

    try {
      if (existing == null) {
        await api.createEvent(body);
        if (!mounted) return;
        showSnack(context, 'Event created ✅');
      } else {
        final id = int.tryParse(existing['event_id']?.toString() ?? '') ?? 0;
        await api.updateEvent(id, body);
        if (!mounted) return;
        showSnack(context, 'Event updated ✅');
      }
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _delete(int id) async {
    try {
      await api.deleteEvent(id);
      if (!mounted) return;
      showSnack(context, 'Deleted ✅');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _openEventForm(), icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder(
        future: api.getEvents(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final list = (data['events'] as List?) ?? const [];

          if (list.isEmpty) {
            return const EmptyState(title: 'No events yet', subtitle: 'Press + to create one.');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = list[i] as Map;
              final id = int.tryParse(e['event_id']?.toString() ?? '') ?? 0;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text((e['title'] ?? 'Event').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('Type: ${e['event_type'] ?? ''} • Start: ${e['start_time'] ?? ''}\nElder: ${e['elder_id'] ?? ''}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _openEventForm(existing: e);
                      if (v == 'delete') _delete(id);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
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

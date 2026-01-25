import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';
import 'package:intl/intl.dart'; // Standard for graduation-level projects

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  // 🎨 Signature Theme Palette
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  // 🛠️ Visual Formatting Helpers
  // 🛠️ Visual Formatting Helpers
  IconData _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'birthday': 
        return Icons.cake_rounded;
      case 'appointment': 
        return Icons.medical_services_rounded; // Standard medical icon
      case 'visit': 
        return Icons.home_rounded;
      case 'medication_refill': 
        return Icons.medication_rounded; // ✅ FIX: Standard Flutter pill/meds icon
      default: 
        return Icons.event_note_rounded;
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'No time set';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (e) {
      return raw;
    }
  }

  // ✅ RETAINED & STYLED: CRUD Form Logic
  Future<void> _openEventForm({Map? existing}) async {
    final elderId = TextEditingController(text: existing?['elder_id']?.toString() ?? '');
    final title = TextEditingController(text: (existing?['title'] ?? '').toString());
    final desc = TextEditingController(text: (existing?['description'] ?? '').toString());
    final type = TextEditingController(text: (existing?['event_type'] ?? 'family_event').toString());
    final start = TextEditingController(text: (existing?['start_time'] ?? '2026-01-25 10:00:00').toString());
    final end = TextEditingController(text: (existing?['end_time'] ?? '').toString());
    bool allDay = (existing?['is_all_day']?.toString() ?? '0') == '1';
    final location = TextEditingController(text: (existing?['location'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder( // Allows switch toggle within dialog
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(existing == null ? 'Schedule New Event' : 'Modify Event', 
            style: const TextStyle(fontWeight: FontWeight.w900, color: _deepNavy)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: elderId, label: 'Elder ID (Optional)', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                AppTextField(controller: title, label: 'Event Title'),
                const SizedBox(height: 12),
                AppTextField(controller: desc, label: 'Description', maxLines: 2),
                const SizedBox(height: 12),
                AppTextField(controller: type, label: 'Type (birthday/appointment/visit)'),
                const SizedBox(height: 12),
                AppTextField(controller: start, label: 'Start (YYYY-MM-DD HH:MM:SS)'),
                const SizedBox(height: 12),
                AppTextField(controller: end, label: 'End (Optional)'),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: allDay, 
                  onChanged: (v) => setDialogState(() => allDay = v), 
                  title: const Text('All day event', style: TextStyle(fontSize: 14)),
                  activeColor: _sage,
                ),
                AppTextField(controller: location, label: 'Location'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: _denim))),
            FilledButton(
              onPressed: () => Navigator.pop(context, true), 
              style: FilledButton.styleFrom(backgroundColor: _deepNavy),
              child: const Text('Save Event'),
            ),
          ],
        ),
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
        showSnack(context, 'Success: Event added ✅');
      } else {
        final id = int.tryParse(existing['event_id']?.toString() ?? '') ?? 0;
        await api.updateEvent(id, body);
        if (!mounted) return;
        showSnack(context, 'Success: Event updated ✅');
      }
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  // ✅ RETAINED FUNCTIONALITY: Delete logic
  Future<void> _delete(int id) async {
    try {
      await api.deleteEvent(id);
      if (!mounted) return;
      showSnack(context, 'Event removed ✅');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Care Timeline', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _deepNavy,
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded)),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              onPressed: () => _openEventForm(), 
              icon: const CircleAvatar(
                backgroundColor: _deepNavy,
                child: Icon(Icons.add, color: _cream, size: 20)
              )
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: api.getEvents(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _deepNavy));
          }
          if (snap.hasError) return Center(child: Text('Error loading events: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final list = (data['events'] as List?) ?? const [];

          if (list.isEmpty) {
            return const EmptyState(
              title: 'Timeline is clear', 
              subtitle: 'Add medical checkups or family visits to stay organized.'
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final e = list[i] as Map;
              final type = (e['event_type'] ?? 'other').toString();
              final id = int.tryParse(e['event_id']?.toString() ?? '') ?? 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // 🌈 Contextual Side Bar
                      Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: type == 'birthday' ? Colors.orangeAccent : _sage,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_getEventIcon(type), size: 16, color: _denim),
                                  const SizedBox(width: 8),
                                  Text(type.replaceAll('_', ' ').toUpperCase(), 
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _denim, letterSpacing: 1.2)),
                                  const Spacer(),
                                  _buildActionMenu(e, id),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text((e['title'] ?? 'Care Event').toString(), 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepNavy)),
                              if (e['description'] != null && e['description'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(e['description'].toString(), style: const TextStyle(fontSize: 13, color: _denim, height: 1.4)),
                                ),
                              const Divider(height: 32),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, size: 14, color: _sage),
                                  const SizedBox(width: 6),
                                  Text(_formatDateTime(e['start_time']), 
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _deepNavy)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildActionMenu(Map e, int id) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded, color: _denim, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (v) {
        if (v == 'edit') _openEventForm(existing: e);
        if (v == 'delete') _delete(id);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Edit Details')])),
        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 10), Text('Remove Event', style: TextStyle(color: Colors.red))])),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementNotesPage extends StatefulWidget {
  const RetirementNotesPage({super.key});

  @override
  State<RetirementNotesPage> createState() => _RetirementNotesPageState();
}

class _RetirementNotesPageState extends State<RetirementNotesPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _notes = [];
  final _elderFilter = TextEditingController(); // optional: filter by elderId

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _elderFilter.dispose();
    super.dispose();
  }

  Future<void> _load({int? elderId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = elderId == null ? await _api.getHomeNotes() : await _api.getElderNotes(elderId);
      setState(() {
        _notes = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openCreate() async {
    final elderIdC = TextEditingController();
    final caregiverIdC = TextEditingController();
    final titleC = TextEditingController();
    final noteC = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Note'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: elderIdC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Elder ID (optional)'),
              ),
              TextField(
                controller: caregiverIdC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Caregiver ID (optional)'),
              ),
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: 'Title (optional)'),
              ),
              TextField(
                controller: noteC,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Note (required)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    final elderId = int.tryParse(elderIdC.text.trim());
    final caregiverId = int.tryParse(caregiverIdC.text.trim());
    final title = titleC.text.trim().isEmpty ? null : titleC.text.trim();
    final note = noteC.text.trim();

    elderIdC.dispose();
    caregiverIdC.dispose();
    titleC.dispose();
    noteC.dispose();

    if (ok != true) return;
    if (note.isEmpty) {
      _snack('Note is required.');
      return;
    }

    try {
      await _api.createNote(elderId: elderId, caregiverId: caregiverId, title: title, note: note);
      _snack('Note created ✅');
      await _load();
    } catch (e) {
      _snack('Create failed: $e');
    }
  }

  Future<void> _openEdit(Map<String, dynamic> n) async {
    final id = (n['note_id'] as num?)?.toInt();
    if (id == null) return;

    final titleC = TextEditingController(text: (n['title'] ?? '').toString());
    final noteC = TextEditingController(text: (n['note'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Note #$id'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                controller: noteC,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );

    final title = titleC.text.trim().isEmpty ? null : titleC.text.trim();
    final note = noteC.text.trim().isEmpty ? null : noteC.text.trim();

    titleC.dispose();
    noteC.dispose();

    if (ok != true) return;

    try {
      await _api.updateNote(noteId: id, title: title, note: note);
      _snack('Note updated ✅');
      await _load();
    } catch (e) {
      _snack('Update failed: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> n) async {
    final id = (n['note_id'] as num?)?.toInt();
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('This will delete note #$id permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _api.deleteNote(id);
      _snack('Deleted ✅');
      await _load();
    } catch (e) {
      _snack('Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Notes'),
        actions: [
          IconButton(onPressed: () => _load(), icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _openCreate, icon: const Icon(Icons.add)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _elderFilter,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Elder ID (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final id = int.tryParse(_elderFilter.text.trim());
                      _load(elderId: id);
                    },
                    child: const Text('Apply'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      _elderFilter.clear();
                      _load();
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_notes.isEmpty)
            const Center(child: Text('No notes yet.'))
          else
            ..._notes.map((n) {
              final id = n['note_id'] ?? '-';
              final title = (n['title'] ?? 'Note').toString();
              final note = (n['note'] ?? '').toString();
              final elderName = (n['elder_name'] ?? '').toString();
              final caregiverName = (n['caregiver_name'] ?? '').toString();
              final createdAt = (n['created_at'] ?? '').toString();

              final meta = [
                if (elderName.isNotEmpty) 'Elder: $elderName',
                if (caregiverName.isNotEmpty) 'Caregiver: $caregiverName',
                if (createdAt.isNotEmpty) 'Created: $createdAt',
              ].join(' • ');

              return Card(
                child: ListTile(
                  title: Text('$title (#$id)', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${meta.isEmpty ? '' : '$meta\n'}$note'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _openEdit(n);
                      if (v == 'delete') _delete(n);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

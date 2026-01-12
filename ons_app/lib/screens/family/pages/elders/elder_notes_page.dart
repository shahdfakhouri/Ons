import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class ElderNotesPage extends StatefulWidget {
  final int elderId;
  const ElderNotesPage({super.key, required this.elderId});

  @override
  State<ElderNotesPage> createState() => _ElderNotesPageState();
}

class _ElderNotesPageState extends State<ElderNotesPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (note.text.trim().isEmpty) return;
    try {
      await api.addFamilyNote(widget.elderId, note.text.trim());
      if (!mounted) return;
      note.clear();
      showSnack(context, 'Note added ✅');
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
        title: const Text('Family Notes'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  AppTextField(controller: note, label: 'Write a note', maxLines: 3),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _add, child: const Text('Add note'))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SectionTitle('Notes list'),
          FutureBuilder(
            future: api.getFamilyNotes(elderId),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final list = (data['notes'] as List?) ?? const [];
              if (list.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No notes yet.')));

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = list[i] as Map;
                    return ListTile(
                      leading: const Icon(Icons.note),
                      title: Text((n['note_text'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text((n['created_at'] ?? '').toString()),
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

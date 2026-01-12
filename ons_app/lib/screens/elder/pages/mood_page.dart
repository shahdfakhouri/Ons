import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/mood_history_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  final api = ElderApi();
  int mood = 3;
  final notesCtrl = TextEditingController();
  bool loading = false;

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      await api.addMood(moodLevel: mood, notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mood saved ✅')));
      notesCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodHistoryPage())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'How are you feeling?',
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(5, (i) {
                    final level = i + 1;
                    final selected = level == mood;
                    return ChoiceChip(
                      label: Text(' $level ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      selected: selected,
                      onSelected: (_) => setState(() => mood = level),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Optional note',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send),
                    label: Text(loading ? 'Sending...' : 'Submit'),
                    onPressed: loading ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

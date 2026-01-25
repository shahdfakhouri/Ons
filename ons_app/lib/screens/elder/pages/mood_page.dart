import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/mood_history_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class MoodPage extends StatefulWidget {
  // ✅ 1. Define the named parameter in the Widget class
  final void Function(int index)? onBack;
  const MoodPage({super.key, this.onBack});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  final api = ElderApi();
  int mood = 3;
  final notesCtrl = TextEditingController();
  bool loading = false;

  // ✅ 2. Define a helper to trigger the back navigation to Index 0 (Home)
  void _triggerBack() {
    if (widget.onBack != null) {
      widget.onBack!(0);
    }
  }

  @override
  void dispose() {
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      await api.addMood(
        moodLevel: mood, 
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim()
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mood saved ✅')));
      notesCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 3. Use PopScope to handle the physical back button
    return PopScope(
      canPop: false, // Prevents exiting to the website landing page
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        appBar: AppBar(
          // ✅ 4. Use custom leading button to go to Elder Home (Index 0)
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _triggerBack,
          ),
          title: const Text('Mood'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const MoodHistoryPage())
              ),
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
      ),
    );
  }
}
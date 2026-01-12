import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/symptoms_history_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class SymptomsPage extends StatefulWidget {
  const SymptomsPage({super.key});

  @override
  State<SymptomsPage> createState() => _SymptomsPageState();
}

class _SymptomsPageState extends State<SymptomsPage> {
  final api = ElderApi();

  final symptomCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String severity = 'low';
  bool loading = false;

  Future<void> _submit() async {
    final symptom = symptomCtrl.text.trim();
    if (symptom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter symptom')));
      return;
    }

    setState(() => loading = true);
    try {
      await api.addSymptom(symptom: symptom, severity: severity, notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Symptom submitted ✅')));
      symptomCtrl.clear();
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
        title: const Text('Symptoms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomsHistoryPage())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Report symptom',
            child: Column(
              children: [
                TextField(
                  controller: symptomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Symptom',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (v) => setState(() => severity = v ?? 'low'),
                ),
                const SizedBox(height: 10),
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

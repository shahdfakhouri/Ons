import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/symptoms_history_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class SymptomsPage extends StatefulWidget {
  // ✅ 1. Accept the onBack navigation callback
  final void Function(int index)? onBack;
  const SymptomsPage({super.key, this.onBack});

  @override
  State<SymptomsPage> createState() => _SymptomsPageState();
}

class _SymptomsPageState extends State<SymptomsPage> {
  final api = ElderApi();

  final symptomCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String severity = 'low';
  bool loading = false;

  // ✅ 2. Define helper to return to Index 0 (Home)
  void _triggerBack() {
    if (widget.onBack != null) {
      widget.onBack!(0);
    }
  }

  @override
  void dispose() {
    symptomCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final symptom = symptomCtrl.text.trim();
    if (symptom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter symptom'))
      );
      return;
    }

    setState(() => loading = true);
    try {
      await api.addSymptom(
        symptom: symptom, 
        severity: severity, 
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim()
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptom submitted ✅'))
      );
      symptomCtrl.clear();
      notesCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 3. PopScope ensures device back buttons return to ONS Home
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F4), // ONS Signature Cream
        appBar: AppBar(
          // ✅ 4. Manual back button navigation
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _triggerBack,
          ),
          title: const Text('Symptoms', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const SymptomsHistoryPage())
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Report symptom',
              child: Column(
                children: [
                  TextField(
                    controller: symptomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'What are you feeling?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: severity,
                    decoration: const InputDecoration(
                      labelText: 'Severity', 
                      border: OutlineInputBorder()
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (v) => setState(() => severity = v ?? 'low'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Add more details (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text(loading ? 'Sending...' : 'Submit Report'),
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
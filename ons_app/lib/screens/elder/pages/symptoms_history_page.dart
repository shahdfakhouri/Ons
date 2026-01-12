import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_api.dart';

class SymptomsHistoryPage extends StatefulWidget {
  const SymptomsHistoryPage({super.key});

  @override
  State<SymptomsHistoryPage> createState() => _SymptomsHistoryPageState();
}

class _SymptomsHistoryPageState extends State<SymptomsHistoryPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      items = await api.symptomsHistory();
      setState(() => loading = false);
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptoms History'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i] as Map;
          final symptom = e['symptom']?.toString() ?? '-';
          final sev = e['severity']?.toString() ?? '';
          final notes = e['notes']?.toString() ?? '';
          final date = e['created_at']?.toString() ?? '';
          return Card(
            child: ListTile(
              leading: const Icon(Icons.healing),
              title: Text(symptom, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text([if (sev.isNotEmpty) 'Severity: $sev', if (notes.isNotEmpty) notes, if (date.isNotEmpty) date].join('\n')),
            ),
          );
        },
      ),
    );
  }
}

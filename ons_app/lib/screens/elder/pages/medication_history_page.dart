import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_api.dart';

class MedicationHistoryPage extends StatefulWidget {
  const MedicationHistoryPage({super.key});

  @override
  State<MedicationHistoryPage> createState() => _MedicationHistoryPageState();
}

class _MedicationHistoryPageState extends State<MedicationHistoryPage> {
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
      final list = await api.medsHistory();
      setState(() { items = list; loading = false; });
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
        title: const Text('Medication History'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i] as Map;
          final name = (e['name'] ?? e['medicine_name'] ?? 'Medicine').toString();
          final status = (e['status'] ?? e['taken'] ?? '').toString();
          final date = (e['created_at'] ?? e['date'] ?? e['time'] ?? '').toString();
          return Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text([if (status.isNotEmpty) 'Status: $status', if (date.isNotEmpty) 'When: $date'].join(' • ')),
            ),
          );
        },
      ),
    );
  }
}

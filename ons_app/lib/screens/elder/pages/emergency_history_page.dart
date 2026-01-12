import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_api.dart';

class EmergencyHistoryPage extends StatefulWidget {
  const EmergencyHistoryPage({super.key});

  @override
  State<EmergencyHistoryPage> createState() => _EmergencyHistoryPageState();
}

class _EmergencyHistoryPageState extends State<EmergencyHistoryPage> {
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
      items = await api.myEmergencies();
      setState(() => loading = false);
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _cancel(dynamic e) async {
    final id = e['emergency_id'] ?? e['id'];
    if (id == null) return;

    try {
      await api.cancelEmergency(int.parse('$id'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelled ✅')));
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency History'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i] as Map;
          final id = (e['emergency_id'] ?? e['id'])?.toString() ?? '';
          final status = e['status']?.toString() ?? '';
          final type = e['emergency_type']?.toString() ?? '';
          final date = e['created_at']?.toString() ?? '';
          final canCancel = status.toLowerCase() == 'open';

          return Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text('Emergency #$id', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text([if (type.isNotEmpty) 'Type: $type', if (status.isNotEmpty) 'Status: $status', if (date.isNotEmpty) date].join(' • ')),
              trailing: canCancel
                  ? OutlinedButton(
                      onPressed: () => _cancel(e),
                      child: const Text('Cancel'),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

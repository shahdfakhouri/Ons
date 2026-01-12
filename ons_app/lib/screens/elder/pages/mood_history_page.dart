import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_api.dart';

class MoodHistoryPage extends StatefulWidget {
  const MoodHistoryPage({super.key});

  @override
  State<MoodHistoryPage> createState() => _MoodHistoryPageState();
}

class _MoodHistoryPageState extends State<MoodHistoryPage> {
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
      items = await api.moodHistory();
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
        title: const Text('Mood History'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i] as Map;
          final level = e['mood_level']?.toString() ?? '-';
          final notes = e['notes']?.toString() ?? '';
          final date = e['created_at']?.toString() ?? '';
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(level, style: const TextStyle(fontWeight: FontWeight.w800))),
              title: Text('Mood: $level', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text([if (notes.isNotEmpty) notes, if (date.isNotEmpty) date].join('\n')),
            ),
          );
        },
      ),
    );
  }
}

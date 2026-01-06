import 'package:flutter/material.dart';
import 'package:ons_app/services/caregiver_api.dart';
import 'elder_detail_page.dart';

class EldersPage extends StatefulWidget {
  const EldersPage({super.key});

  @override
  State<EldersPage> createState() => _EldersPageState();
}

class _EldersPageState extends State<EldersPage> {
  final _api = CaregiverApi();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _elders = [];
  String _q = '';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final elders = await _api.getAssignedElders();
      setState(() {
        _elders = elders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load elders', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _elders.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      return name.contains(_q.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
                hintText: 'Search elders by name...',
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No elders found.', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        for (final e in filtered)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                foregroundColor: cs.onSecondaryContainer,
                child: Text(((e['name'] ?? 'E').toString()).substring(0, 1).toUpperCase()),
              ),
              title: Text((e['name'] ?? 'Unknown').toString()),
              subtitle: Text(
                'Age: ${e['age'] ?? '-'} • Gender: ${e['gender'] ?? '-'}\nLast check-in: ${e['last_check_in'] ?? '-'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final id = int.tryParse(e['elder_id'].toString());
                if (id == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ElderDetailPage(elderId: id)),
                );
              },
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/caregiver_api.dart';
import 'incident_detail_page.dart';

class IncidentsPage extends StatefulWidget {
  const IncidentsPage({super.key});

  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  final _api = CaregiverApi();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _incidents = [];

  String _fmt(dynamic v) {
    if (v == null) return '-';
    try {
      return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(v.toString()));
    } catch (_) {
      return v.toString();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getMyIncidents();
      setState(() {
        _incidents = list;
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
                Text('Failed to load incidents', style: Theme.of(context).textTheme.titleMedium),
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

    if (_incidents.isEmpty) {
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No incidents found.'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('My incidents', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final i in _incidents)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                  child: const Icon(Icons.report),
                ),
                title: Text('${i['elder_name'] ?? 'Elder'} • ${i['type'] ?? 'other'}'),
                subtitle: Text(
                  'Severity: ${i['severity'] ?? '-'} • Status: ${i['status'] ?? '-'}\n'
                  'Occurred: ${_fmt(i['occurred_at'])}\n'
                  '${i['title'] ?? ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final id = int.tryParse(i['incident_id'].toString());
                  if (id == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => IncidentDetailPage(incidentId: id)),
                  ).then((_) => _load());
                },
              ),
            ),
        ],
      ),
    );
  }
}

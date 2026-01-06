import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/caregiver_api.dart';

class VisitsPage extends StatefulWidget {
  const VisitsPage({super.key});

  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage> {
  final _api = CaregiverApi();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _visits = [];

  String _status = 'all'; // all | pending | approved
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

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
      final visits = await _api.getMyUpcomingVisits(
        status: _status,
        from: _fromCtrl.text.trim().isEmpty ? null : _fromCtrl.text.trim(),
        to: _toCtrl.text.trim().isEmpty ? null : _toCtrl.text.trim(),
      );
      setState(() {
        _visits = visits;
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
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load visits', style: Theme.of(context).textTheme.titleMedium),
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All')),
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'approved', child: Text('Approved')),
                          ],
                          onChanged: (v) => setState(() => _status = v ?? 'all'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.search),
                        label: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fromCtrl,
                          decoration: const InputDecoration(
                            labelText: 'From (YYYY-MM-DD)',
                            hintText: '2026-01-01',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _toCtrl,
                          decoration: const InputDecoration(
                            labelText: 'To (YYYY-MM-DD)',
                            hintText: '2026-01-31',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_visits.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No upcoming visits.'),
              ),
            ),

          for (final v in _visits)
            Card(
              child: ListTile(
                title: Text('${v['elder_name'] ?? '-'} • ${_fmt(v['scheduled_at'])}'),
                subtitle: Text(
                  'Duration: ${v['duration_minutes'] ?? '-'} min • Status: ${v['status'] ?? '-'}\n'
                  'Family: ${v['family_name'] ?? '-'} (${v['family_phone'] ?? '-'})\n'
                  '${v['notes'] ?? ''}',
                ),
                trailing: const Icon(Icons.event),
              ),
            ),
        ],
      ),
    );
  }
}

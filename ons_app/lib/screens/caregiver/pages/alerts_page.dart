import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/caregiver_api.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final _api = CaregiverApi();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _alerts = [];

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
      final alerts = await _api.getMyAlerts();
      setState(() {
        _alerts = alerts;
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
                Text('Failed to load alerts', style: Theme.of(context).textTheme.titleMedium),
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

    if (_alerts.isEmpty) {
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No open alerts ✅'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Open alerts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final a in _alerts)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                  child: const Icon(Icons.notifications),
                ),
                title: Text((a['message'] ?? 'Alert').toString()),
                subtitle: Text(
                  'Elder: ${a['elder_name'] ?? '-'} (#${a['elder_id'] ?? '-'})\n'
                  'Type: ${a['type'] ?? '-'} • Created: ${_fmt(a['created_at'])}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(
                    (a['severity'] ?? 'medium').toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementAlertsPage extends StatefulWidget {
  const RetirementAlertsPage({super.key});

  @override
  State<RetirementAlertsPage> createState() => _RetirementAlertsPageState();
}

class _RetirementAlertsPageState extends State<RetirementAlertsPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _alerts = [];

  String _status = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getAlerts(status: _status, limit: 100);
      setState(() {
        _alerts = list;
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
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text('Alerts', style: Theme.of(context).textTheme.titleLarge)),
              DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('open')),
                  DropdownMenuItem(value: 'resolved', child: Text('resolved')),
                  DropdownMenuItem(value: 'all', child: Text('all')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _status = v);
                  await _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_alerts.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No alerts found.')))
          else
            ..._alerts.map((a) {
              final type = (a['type'] ?? '').toString();
              final msg = (a['message'] ?? '').toString();
              final sev = (a['severity'] ?? '').toString();
              final status = (a['status'] ?? '').toString();
              final elderName = (a['elder_name'] ?? '').toString();
              final created = (a['created_at'] ?? '').toString();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text('$type • $elderName'),
                  subtitle: Text('Severity: $sev • Status: $status\n$msg\n$created'),
                ),
              );
            }),
        ],
      ),
    );
  }
}

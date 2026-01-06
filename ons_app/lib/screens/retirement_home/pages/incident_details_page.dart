import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementIncidentDetailsPage extends StatefulWidget {
  final int incidentId;
  const RetirementIncidentDetailsPage({super.key, required this.incidentId});

  @override
  State<RetirementIncidentDetailsPage> createState() => _RetirementIncidentDetailsPageState();
}

class _RetirementIncidentDetailsPageState extends State<RetirementIncidentDetailsPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _incident;

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
      final inc = await _api.getIncidentById(widget.incidentId);
      setState(() {
        _incident = inc;
        _status = (inc['status'] ?? 'open').toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String s) async {
    try {
      await _api.updateIncidentStatus(widget.incidentId, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated ✅')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));

    final i = _incident ?? {};

    return Scaffold(
      appBar: AppBar(title: Text('Incident #${widget.incidentId}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Type: ${i['type']}\n'
                  'Severity: ${i['severity']}\n'
                  'Status: ${i['status']}\n'
                  'Elder ID: ${i['elder_id']}\n'
                  'Caregiver ID: ${i['caregiver_id'] ?? '—'}\n'
                  'Description: ${i['description']}\n'
                  'Created: ${i['created_at']}\n'
                  'Resolved: ${i['resolved_at'] ?? '—'}\n',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Update status', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('open')),
                    DropdownMenuItem(value: 'investigating', child: Text('investigating')),
                    DropdownMenuItem(value: 'resolved', child: Text('resolved')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _status = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => _updateStatus(_status),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

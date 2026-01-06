import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/caregiver_api.dart';

class IncidentDetailPage extends StatefulWidget {
  final int incidentId;
  const IncidentDetailPage({super.key, required this.incidentId});

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  final _api = CaregiverApi();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _incident;

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
      final incident = await _api.getIncidentById(widget.incidentId);
      setState(() {
        _incident = incident;
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
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident')),
        body: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed to load incident', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final i = _incident ?? {};
    final status = (i['status'] ?? 'open').toString();

    return Scaffold(
      appBar: AppBar(title: Text('Incident #${widget.incidentId}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((i['title'] ?? 'Incident').toString(), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Elder: ${i['elder_name'] ?? '-'} (#${i['elder_id'] ?? '-'})'),
                  Text('Type: ${i['type'] ?? '-'} • Severity: ${i['severity'] ?? '-'}'),
                  Text('Occurred: ${_fmt(i['occurred_at'])}'),
                  Text('Created: ${_fmt(i['created_at'])}'),
                  const SizedBox(height: 12),
                  Text('Description:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text((i['description'] ?? '-').toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatusBtn(label: 'Open', active: status == 'open', onTap: () => _updateStatus('open')),
                      _StatusBtn(label: 'Reviewing', active: status == 'reviewing', onTap: () => _updateStatus('reviewing')),
                      _StatusBtn(label: 'Resolved', active: status == 'resolved', onTap: () => _updateStatus('resolved')),
                      _StatusBtn(label: 'Closed', active: status == 'closed', onTap: () => _updateStatus('closed')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StatusBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return active
        ? FilledButton(onPressed: onTap, child: Text(label))
        : OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

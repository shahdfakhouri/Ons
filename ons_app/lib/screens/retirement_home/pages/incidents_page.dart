import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'incident_details_page.dart';

class RetirementIncidentsPage extends StatefulWidget {
  const RetirementIncidentsPage({super.key});

  @override
  State<RetirementIncidentsPage> createState() => _RetirementIncidentsPageState();
}

class _RetirementIncidentsPageState extends State<RetirementIncidentsPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;

  String _status = 'all';
  List<Map<String, dynamic>> _incidents = [];

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
      final list = await _api.getIncidents(status: _status);
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

  Future<void> _createIncident() async {
    final elderIdC = TextEditingController();
    final caregiverIdC = TextEditingController();
    final typeC = TextEditingController();
    final severityC = TextEditingController(text: 'medium');
    final descC = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create incident'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: elderIdC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'elder_id (required)')),
              TextField(controller: caregiverIdC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'caregiver_id (optional)')),
              TextField(controller: typeC, decoration: const InputDecoration(labelText: 'type (required)')),
              TextField(controller: severityC, decoration: const InputDecoration(labelText: 'severity (low/medium/high)')),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'description (required)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) return;

    final elderId = int.tryParse(elderIdC.text.trim());
    final caregiverId = int.tryParse(caregiverIdC.text.trim());

    elderIdC.dispose();
    caregiverIdC.dispose();
    typeC.dispose();
    severityC.dispose();
    descC.dispose();

    if (elderId == null || typeC.text.trim().isEmpty || descC.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('elder_id, type, description required')));
      return;
    }

    try {
      await _api.createIncident({
        'elder_id': elderId,
        'caregiver_id': caregiverId,
        'type': typeC.text.trim(),
        'severity': severityC.text.trim().isEmpty ? 'medium' : severityC.text.trim(),
        'description': descC.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident created ✅')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
              Expanded(child: Text('Incidents', style: Theme.of(context).textTheme.titleLarge)),
              DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('all')),
                  DropdownMenuItem(value: 'open', child: Text('open')),
                  DropdownMenuItem(value: 'investigating', child: Text('investigating')),
                  DropdownMenuItem(value: 'resolved', child: Text('resolved')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _status = v);
                  await _load();
                },
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _createIncident, icon: const Icon(Icons.add), label: const Text('New')),
            ],
          ),
          const SizedBox(height: 12),
          if (_incidents.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No incidents found.')))
          else
            ..._incidents.map((i) {
              final id = (i['incident_id'] ?? 0) as num;
              final type = (i['type'] ?? '').toString();
              final sev = (i['severity'] ?? '').toString();
              final status = (i['status'] ?? '').toString();
              final elderName = (i['elder_name'] ?? '').toString();
              final created = (i['created_at'] ?? '').toString();

              return Card(
                child: ListTile(
                  title: Text('Incident #${id.toInt()} • $type • $sev'),
                  subtitle: Text('Elder: $elderName • Status: $status\n$created'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RetirementIncidentDetailsPage(incidentId: id.toInt())),
                  ).then((_) => _load()),
                ),
              );
            }),
        ],
      ),
    );
  }
}

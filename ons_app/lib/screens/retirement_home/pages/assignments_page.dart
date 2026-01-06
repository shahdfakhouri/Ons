import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementAssignmentsPage extends StatefulWidget {
  const RetirementAssignmentsPage({super.key});

  @override
  State<RetirementAssignmentsPage> createState() => _RetirementAssignmentsPageState();
}

class _RetirementAssignmentsPageState extends State<RetirementAssignmentsPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _assignments = [];

  // simple input fields (IDs)
  final _elderId = TextEditingController();
  final _caregiverId = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _elderId.dispose();
    _caregiverId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getAssignments();
      setState(() {
        _assignments = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _assign() async {
    final elder = int.tryParse(_elderId.text.trim());
    final caregiver = int.tryParse(_caregiverId.text.trim());
    if (elder == null || caregiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid elder_id & caregiver_id')));
      return;
    }

    try {
      await _api.assignCaregiverToElder(elderId: elder, caregiverId: caregiver);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assigned ✅')));
      _elderId.clear();
      _caregiverId.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _remove(int elderId, int caregiverId) async {
    try {
      await _api.removeAssignment(elderId: elderId, caregiverId: caregiverId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed ❎')));
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
          Text('Create assignment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _elderId,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'elder_id'),
                  ),
                  TextField(
                    controller: _caregiverId,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'caregiver_id'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _assign,
                      icon: const Icon(Icons.link),
                      label: const Text('Assign'),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Current assignments', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_assignments.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No assignments yet.')))
          else
            ..._assignments.map((a) {
              final elderId = (a['elder_id'] ?? 0) as num;
              final caregiverId = (a['caregiver_id'] ?? 0) as num;
              final elderName = (a['elder_name'] ?? '').toString();
              final caregiverName = (a['caregiver_name'] ?? '').toString();
              final assignedAt = (a['assigned_at'] ?? '').toString();

              return Card(
                child: ListTile(
                  title: Text('Elder ${elderId.toInt()} $elderName  →  Caregiver ${caregiverId.toInt()} $caregiverName'),
                  subtitle: Text(assignedAt.isEmpty ? '' : 'Assigned at: $assignedAt'),
                  trailing: IconButton(
                    icon: const Icon(Icons.link_off),
                    onPressed: () => _remove(elderId.toInt(), caregiverId.toInt()),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

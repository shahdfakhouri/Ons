import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementCaregiversPage extends StatefulWidget {
  const RetirementCaregiversPage({super.key});

  @override
  State<RetirementCaregiversPage> createState() => _RetirementCaregiversPageState();
}

class _RetirementCaregiversPageState extends State<RetirementCaregiversPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _home = [];
  List<Map<String, dynamic>> _available = [];

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
      final home = await _api.getHomeCaregivers();
      final avail = await _api.getAvailableCaregivers();
      setState(() {
        _home = home;
        _available = avail;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addCaregiver(int caregiverId) async {
    try {
      await _api.addCaregiverToHome(caregiverId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caregiver added ✅')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _removeCaregiver(int caregiverId) async {
    try {
      await _api.removeCaregiverFromHome(caregiverId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caregiver removed ❎')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _openAvailablePicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _available.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = _available[i];
            final id = (c['caregiver_id'] ?? 0) as num;
            final name = (c['name'] ?? 'Caregiver').toString();
            final phone = (c['phone'] ?? '').toString();
            return ListTile(
              title: Text('$name (ID: ${id.toInt()})'),
              subtitle: Text(phone.isEmpty ? '—' : phone),
              trailing: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addCaregiver(id.toInt());
                },
                child: const Text('Add'),
              ),
            );
          },
        );
      },
    );
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
              Expanded(child: Text('Home Caregivers', style: Theme.of(context).textTheme.titleLarge)),
              FilledButton.icon(
                onPressed: _openAvailablePicker,
                icon: const Icon(Icons.person_add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_home.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No caregivers assigned yet.')))
          else
            ..._home.map((c) {
              final id = (c['caregiver_id'] ?? 0) as num;
              final name = (c['name'] ?? 'Caregiver').toString();
              final email = (c['email'] ?? '').toString();
              final phone = (c['phone'] ?? '').toString();
              final status = (c['status'] ?? 'unknown').toString();
              final assignedAt = (c['assigned_at'] ?? '').toString();

              return Card(
                child: ListTile(
                  title: Text('$name (ID: ${id.toInt()})'),
                  subtitle: Text([
                    if (email.isNotEmpty) email,
                    if (phone.isNotEmpty) phone,
                    'Status: $status',
                    if (assignedAt.isNotEmpty) 'Assigned: $assignedAt',
                  ].join(' • ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeCaregiver(id.toInt()),
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          Text('Available caregivers: ${_available.length}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

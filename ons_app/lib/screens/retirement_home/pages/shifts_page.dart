import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementShiftsPage extends StatefulWidget {
  const RetirementShiftsPage({super.key});

  @override
  State<RetirementShiftsPage> createState() => _RetirementShiftsPageState();
}

class _RetirementShiftsPageState extends State<RetirementShiftsPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _active = [];

  final _caregiverId = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  @override
  void dispose() {
    _caregiverId.dispose();
    super.dispose();
  }

  Future<void> _loadActive() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getActiveShifts();
      setState(() {
        _active = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startEnd(bool start) async {
    final id = int.tryParse(_caregiverId.text.trim());
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter caregiver_id')));
      return;
    }

    final notes = await _askNotes();

    try {
      if (start) {
        await _api.startShift(id, notes: notes);
      } else {
        await _api.endShift(id, notes: notes);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(start ? 'Shift started ✅' : 'Shift ended ✅')));
      await _loadActive();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<String?> _askNotes() async {
    final c = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notes (optional)'),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Write a note...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Skip')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    c.dispose();
    return result;
  }

  Future<void> _openHistory(int caregiverId) async {
    try {
      final list = await _api.getCaregiverShiftHistory(caregiverId, limit: 30);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final s = list[i];
            return Card(
              child: ListTile(
                title: Text('Start: ${s['shift_start'] ?? '-'}'),
                subtitle: Text('End: ${s['shift_end'] ?? '-'}\nNotes: ${s['notes'] ?? '—'}'),
              ),
            );
          },
        ),
      );
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
      onRefresh: _loadActive,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Manage shifts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _caregiverId,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'caregiver_id'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _startEnd(false),
                          icon: const Icon(Icons.stop),
                          label: const Text('End shift'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _startEnd(true),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start shift'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Active shifts now', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_active.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No active shifts.')))
          else
            ..._active.map((a) {
              final caregiverId = (a['caregiver_id'] ?? 0) as num;
              final name = (a['caregiver_name'] ?? '').toString();
              final start = (a['shift_start'] ?? '').toString();
              return Card(
                child: ListTile(
                  title: Text('$name (ID: ${caregiverId.toInt()})'),
                  subtitle: Text('Shift start: $start'),
                  trailing: TextButton(
                    onPressed: () => _openHistory(caregiverId.toInt()),
                    child: const Text('History'),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

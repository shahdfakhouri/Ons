import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/caregiver_api.dart';

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  final _api = CaregiverApi();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _active;
  List<Map<String, dynamic>> _history = [];

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
      final active = await _api.getMyActiveShift();
      final history = await _api.getMyShiftHistory(limit: 50);
      setState(() {
        _active = active;
        _history = history;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start shift'),
        content: TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.startMyShift(notes: notes.text.trim().isEmpty ? null : notes.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift started ✅')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _end() async {
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End shift'),
        content: TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.endMyShift(notes: notes.text.trim().isEmpty ? null : notes.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift ended ✅')));
      _load();
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
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load shifts', style: Theme.of(context).textTheme.titleMedium),
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
          // Active shift card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _active == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No active shift', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: const Text('Start shift')),
                        const SizedBox(height: 6),
                  
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Active shift', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Started: ${_fmt(_active!['shift_start'])}'),
                        Text('Home: ${_active!['home_name'] ?? '-'}'),

                        const SizedBox(height: 10),
                        FilledButton.icon(onPressed: _end, icon: const Icon(Icons.stop), label: const Text('End shift')),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          if (_history.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No shift history.'),
              ),
            ),

          for (final s in _history)
            Card(
              child: ListTile(
                title: Text('Start: ${_fmt(s['shift_start'])}'),
                subtitle: Text('End: ${_fmt(s['shift_end'])}\nNotes: ${s['notes'] ?? '-'}'),
                trailing: Text('#${s['shift_id'] ?? '-'}'),
              ),
            ),
        ],
      ),
    );
  }
}

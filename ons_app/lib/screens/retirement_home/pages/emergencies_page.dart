import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementEmergenciesPage extends StatefulWidget {
  const RetirementEmergenciesPage({super.key});

  @override
  State<RetirementEmergenciesPage> createState() => _RetirementEmergenciesPageState();
}

class _RetirementEmergenciesPageState extends State<RetirementEmergenciesPage> {
  final _api = RetirementHomeApi();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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
      final list = await _api.getEmergencies();
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _act(int emergencyId, bool accept) async {
    try {
      if (accept) {
        await _api.acceptEmergency(emergencyId);
      } else {
        await _api.rejectEmergency(emergencyId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Emergency accepted ✅' : 'Emergency rejected ❎')),
      );
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
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final e = _items[i];
          final id = (e['emergency_id'] ?? e['id'] ?? 0) as num;
          final status = (e['status'] ?? 'unknown').toString();
          final title = (e['type'] ?? e['title'] ?? 'Emergency').toString();
          final msg = (e['message'] ?? e['description'] ?? '').toString();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('$title (ID: ${id.toInt()})', style: Theme.of(context).textTheme.titleMedium)),
                      Chip(label: Text(status)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(msg.isEmpty ? '—' : msg),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _act(id.toInt(), false),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _act(id.toInt(), true),
                          icon: const Icon(Icons.check),
                          label: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

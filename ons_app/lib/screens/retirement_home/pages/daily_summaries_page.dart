import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementDailySummariesPage extends StatefulWidget {
  const RetirementDailySummariesPage({super.key});

  @override
  State<RetirementDailySummariesPage> createState() => _RetirementDailySummariesPageState();
}

class _RetirementDailySummariesPageState extends State<RetirementDailySummariesPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;

  String? _date; // yyyy-mm-dd or null (today)
  List<Map<String, dynamic>> _summaries = [];

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
      final list = await _api.getHomeDailySummaries(date: _date);
      setState(() {
        _summaries = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    final s = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() => _date = s);
    await _load();
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
              Expanded(child: Text('Daily summaries', style: Theme.of(context).textTheme.titleLarge)),
              TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.date_range), label: Text(_date ?? 'Today')),
              if (_date != null)
                TextButton(
                  onPressed: () async {
                    setState(() => _date = null);
                    await _load();
                  },
                  child: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_summaries.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No summaries found.')))
          else
            ..._summaries.map((s) {
              final elderName = (s['elder_name'] ?? '').toString();
              final mood = (s['mood'] ?? '').toString();
              final meals = (s['meals'] ?? '').toString();
              final activities = (s['activities'] ?? '').toString();
              final updated = (s['updated_at'] ?? '').toString();
              return Card(
                child: ListTile(
                  title: Text(elderName),
                  subtitle: Text('Mood: $mood\nMeals: $meals\nActivities: $activities\nUpdated: $updated'),
                ),
              );
            }),
        ],
      ),
    );
  }
}

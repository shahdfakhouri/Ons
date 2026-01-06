import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementElderDetailsPage extends StatefulWidget {
  final int elderId;
  const RetirementElderDetailsPage({super.key, required this.elderId});

  @override
  State<RetirementElderDetailsPage> createState() => _RetirementElderDetailsPageState();
}

class _RetirementElderDetailsPageState extends State<RetirementElderDetailsPage> with TickerProviderStateMixin {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _elder;
  List<Map<String, dynamic>> _healthLogs = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _attendance = [];
  Map<String, dynamic>? _summary;

  final _summaryMood = TextEditingController();
  final _summaryMeals = TextEditingController();
  final _summaryActivities = TextEditingController();
  bool? _medTaken;
  final _sleepHours = TextEditingController();
  final _summaryNotes = TextEditingController();

  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _summaryMood.dispose();
    _summaryMeals.dispose();
    _summaryActivities.dispose();
    _sleepHours.dispose();
    _summaryNotes.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final elder = await _api.getElderDetails(widget.elderId);
      final logs = await _api.getElderHealthLogs(widget.elderId, limit: 50);
      final loc = await _api.getElderLocationHistory(widget.elderId, limit: 200);
      final att = await _api.getElderAttendance(widget.elderId, limit: 50);
      final sum = await _api.getDailySummary(widget.elderId);

      _elder = elder;
      _healthLogs = logs;
      _locations = loc;
      _attendance = att;
      _summary = sum;

      // prefill summary form (if exists)
      if (sum != null) {
        _summaryMood.text = (sum['mood'] ?? '').toString();
        _summaryMeals.text = (sum['meals'] ?? '').toString();
        _summaryActivities.text = (sum['activities'] ?? '').toString();
        final mt = sum['medication_taken'];
        if (mt == null) {
          _medTaken = null;
        } else if (mt is num) {
          _medTaken = mt.toInt() == 1;
        } else {
          _medTaken = mt.toString() == '1' || mt.toString().toLowerCase() == 'true';
        }
        _sleepHours.text = (sum['sleep_hours'] ?? '').toString();
        _summaryNotes.text = (sum['notes'] ?? '').toString();
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _checkInOut(bool checkIn) async {
    final notes = await _askNotes();
    try {
      if (checkIn) {
        await _api.checkInElder(widget.elderId, notes: notes);
      } else {
        await _api.checkOutElder(widget.elderId, notes: notes);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(checkIn ? 'Checked in ✅' : 'Checked out ✅')),
      );
      await _loadAll();
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

  Future<void> _saveSummary() async {
    try {
      await _api.upsertDailySummary(widget.elderId, {
        'mood': _summaryMood.text.trim().isEmpty ? null : _summaryMood.text.trim(),
        'meals': _summaryMeals.text.trim().isEmpty ? null : _summaryMeals.text.trim(),
        'activities': _summaryActivities.text.trim().isEmpty ? null : _summaryActivities.text.trim(),
        'medication_taken': _medTaken,
        'sleep_hours': int.tryParse(_sleepHours.text.trim()),
        'notes': _summaryNotes.text.trim().isEmpty ? null : _summaryNotes.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily summary saved ✅')));
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final elder = _elder ?? {};
    final name = (elder['name'] ?? elder['elder_name'] ?? 'Elder').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('$name (ID: ${widget.elderId})'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Health Logs'),
            Tab(text: 'Location'),
            Tab(text: 'Attendance'),
            Tab(text: 'Daily Summary'),
          ],
        ),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _detailsTab(elder),
          _healthTab(),
          _locationTab(),
          _attendanceTab(),
          _summaryTab(),
        ],
      ),
    );
  }

  Widget _detailsTab(Map<String, dynamic> elder) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Name: ${elder['name'] ?? elder['elder_name'] ?? ''}'),
                Text('Age: ${elder['age'] ?? ''}'),
                Text('Gender: ${elder['gender'] ?? ''}'),
                Text('DOB: ${elder['dob'] ?? ''}'),
                Text('Location: ${elder['location'] ?? ''}'),
                Text('Last check-in: ${elder['last_check_in'] ?? ''}'),
                const SizedBox(height: 10),
                Text('Caregiver', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Name: ${elder['caregiver_name'] ?? '—'}'),
                Text('Phone: ${elder['caregiver_phone'] ?? '—'}'),
                Text('Email: ${elder['caregiver_email'] ?? '—'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _checkInOut(false),
                icon: const Icon(Icons.logout),
                label: const Text('Check-out'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _checkInOut(true),
                icon: const Icon(Icons.login),
                label: const Text('Check-in'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _healthTab() {
    if (_healthLogs.isEmpty) {
      return const Center(child: Text('No health logs found.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _healthLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final h = _healthLogs[i];
        return Card(
          child: ListTile(
            title: Text('BP: ${h['blood_pressure'] ?? '-'} • Sugar: ${h['blood_sugar'] ?? '-'} • Temp: ${h['temperature'] ?? '-'}'),
            subtitle: Text('Date: ${h['date'] ?? '-'}\nNotes: ${h['notes'] ?? '—'}'),
          ),
        );
      },
    );
  }

  Widget _locationTab() {
    if (_locations.isEmpty) {
      return const Center(child: Text('No location history found.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _locations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final l = _locations[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text('Lat: ${l['latitude'] ?? '-'} • Lng: ${l['longitude'] ?? '-'}'),
            subtitle: Text('Recorded: ${l['recorded_at'] ?? '-'}'),
          ),
        );
      },
    );
  }

  Widget _attendanceTab() {
    if (_attendance.isEmpty) {
      return const Center(child: Text('No attendance history found.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _attendance.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = _attendance[i];
        return Card(
          child: ListTile(
            leading: Icon((a['action'] ?? '').toString().contains('in') ? Icons.login : Icons.logout),
            title: Text('Action: ${a['action'] ?? '-'}'),
            subtitle: Text('Time: ${a['created_at'] ?? '-'}\nNotes: ${a['notes'] ?? '—'}'),
          ),
        );
      },
    );
  }

  Widget _summaryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_summary != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Loaded summary for: ${_summary!['summary_date'] ?? 'today'}\n'
                'Updated: ${_summary!['updated_at'] ?? '-'}',
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(controller: _summaryMood, decoration: const InputDecoration(labelText: 'Mood')),
                TextField(controller: _summaryMeals, decoration: const InputDecoration(labelText: 'Meals')),
                TextField(controller: _summaryActivities, decoration: const InputDecoration(labelText: 'Activities')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        value: _medTaken,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Medication: (unknown)')),
                          DropdownMenuItem(value: true, child: Text('Medication: taken')),
                          DropdownMenuItem(value: false, child: Text('Medication: not taken')),
                        ],
                        onChanged: (v) => setState(() => _medTaken = v),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _sleepHours,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sleep hours'),
                ),
                TextField(controller: _summaryNotes, decoration: const InputDecoration(labelText: 'Notes')),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saveSummary,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Summary'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

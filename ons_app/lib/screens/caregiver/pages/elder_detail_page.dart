import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/caregiver_api.dart';

class ElderDetailPage extends StatefulWidget {
  final int elderId;
  const ElderDetailPage({super.key, required this.elderId});

  @override
  State<ElderDetailPage> createState() => _ElderDetailPageState();
}

class _ElderDetailPageState extends State<ElderDetailPage> {
  final _api = CaregiverApi();
  int _reload = 0;

  void _refreshAll() => setState(() => _reload++);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<Map<String, dynamic>> _loadOverview() async {
    final elder = await _api.getElderDetails(widget.elderId);
    final status = await _api.getElderStatus(widget.elderId);
    return {'elder': elder, 'status': status};
  }

  // ---------------- Dialogs ----------------

  Future<void> _dialogAddHealthLog() async {
    final bp = TextEditingController();
    final bs = TextEditingController();
    final temp = TextEditingController();
    final hr = TextEditingController();
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add health log'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: bp, decoration: const InputDecoration(labelText: 'Blood pressure (e.g. 120/80)')),
              TextField(controller: bs, decoration: const InputDecoration(labelText: 'Blood sugar (e.g. 110)')),
              TextField(controller: temp, decoration: const InputDecoration(labelText: 'Temperature (e.g. 37.2)')),
              TextField(controller: hr, decoration: const InputDecoration(labelText: 'Heart rate (e.g. 72)')),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _api.logElderHealth(widget.elderId, {
        'blood_pressure': bp.text.trim().isEmpty ? null : bp.text.trim(),
        'blood_sugar': bs.text.trim().isEmpty ? null : bs.text.trim(),
        'temperature': temp.text.trim().isEmpty ? null : temp.text.trim(),
        'heart_rate': hr.text.trim().isEmpty ? null : hr.text.trim(),
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      });
      _snack('Health log saved ✅');
      _refreshAll();
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  Future<void> _dialogEditDailySummary(Map<String, dynamic>? existing) async {
    final mood = TextEditingController(text: (existing?['mood'] ?? '').toString());
    final meals = TextEditingController(text: (existing?['meals'] ?? '').toString());
    final activities = TextEditingController(text: (existing?['activities'] ?? '').toString());
    final sleep = TextEditingController(text: (existing?['sleep_hours'] ?? '').toString());
    final medTaken = ValueNotifier<bool?>(existing?['medication_taken'] == null ? null : (existing?['medication_taken'] == 1));
    final notes = TextEditingController(text: (existing?['notes'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Today summary'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: mood, decoration: const InputDecoration(labelText: 'Mood')),
              TextField(controller: meals, decoration: const InputDecoration(labelText: 'Meals'), maxLines: 2),
              TextField(controller: activities, decoration: const InputDecoration(labelText: 'Activities'), maxLines: 2),
              TextField(controller: sleep, decoration: const InputDecoration(labelText: 'Sleep hours (number)')),
              const SizedBox(height: 10),
              ValueListenableBuilder<bool?>(
                valueListenable: medTaken,
                builder: (_, v, __) => DropdownButtonFormField<bool?>(
                  value: v,
                  decoration: const InputDecoration(labelText: 'Medication taken?'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (x) => medTaken.value = x,
                ),
              ),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final sleepNum = double.tryParse(sleep.text.trim());
      await _api.upsertDailySummary(widget.elderId, {
        'mood': mood.text.trim().isEmpty ? null : mood.text.trim(),
        'meals': meals.text.trim().isEmpty ? null : meals.text.trim(),
        'activities': activities.text.trim().isEmpty ? null : activities.text.trim(),
        'medication_taken': medTaken.value == null ? null : (medTaken.value! ? 1 : 0),
        'sleep_hours': sleepNum,
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      });
      _snack('Daily summary saved ✅');
      _refreshAll();
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  Future<void> _dialogCreateIncident() async {
    final type = TextEditingController();
    final severity = ValueNotifier<String>('medium');
    final title = TextEditingController();
    final desc = TextEditingController();
    final occurredAt = TextEditingController(); // optional

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create incident'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: type, decoration: const InputDecoration(labelText: 'Type (fall, health, other...)')),
              ValueListenableBuilder<String>(
                valueListenable: severity,
                builder: (_, v, __) => DropdownButtonFormField<String>(
                  value: v,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: (x) => severity.value = x ?? 'medium',
                ),
              ),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              TextField(
                controller: occurredAt,
                decoration: const InputDecoration(
                  labelText: 'Occurred at (optional)',
                  hintText: 'YYYY-MM-DD HH:mm:ss',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _api.createIncident(widget.elderId, {
        'type': type.text.trim().isEmpty ? null : type.text.trim(),
        'severity': severity.value,
        'title': title.text.trim().isEmpty ? null : title.text.trim(),
        'description': desc.text.trim().isEmpty ? null : desc.text.trim(),
        'occurred_at': occurredAt.text.trim().isEmpty ? null : occurredAt.text.trim(),
      });
      _snack('Incident created ✅');
      _refreshAll();
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  Future<void> _dialogAddLocation() async {
    final lat = TextEditingController();
    final lng = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: lat, decoration: const InputDecoration(labelText: 'Latitude')),
            TextField(controller: lng, decoration: const InputDecoration(labelText: 'Longitude')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    final dLat = double.tryParse(lat.text.trim());
    final dLng = double.tryParse(lng.text.trim());
    if (dLat == null || dLng == null) {
      _snack('Invalid lat/long');
      return;
    }

    try {
      await _api.updateElderLocation(widget.elderId, latitude: dLat, longitude: dLng);
      _snack('Location saved ✅');
      _refreshAll();
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  Future<void> _dialogRequestVisit() async {
    final scheduledAt = TextEditingController();
    final duration = TextEditingController(text: '30');
    final notes = TextEditingController();
    final familyId = TextEditingController(); // optional

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request visit'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: scheduledAt,
                decoration: const InputDecoration(
                  labelText: 'Scheduled at',
                  hintText: 'YYYY-MM-DD HH:mm:ss',
                ),
              ),
              TextField(controller: duration, decoration: const InputDecoration(labelText: 'Duration minutes')),
              TextField(controller: familyId, decoration: const InputDecoration(labelText: 'Family ID (optional)')),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Request')),
        ],
      ),
    );

    if (ok != true) return;

    final dur = int.tryParse(duration.text.trim());
    if (scheduledAt.text.trim().isEmpty || dur == null) {
      _snack('scheduled_at and duration are required');
      return;
    }

    try {
      final body = <String, dynamic>{
        'scheduled_at': scheduledAt.text.trim(),
        'duration_minutes': dur,
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      };
      final fam = int.tryParse(familyId.text.trim());
      if (fam != null) body['family_id'] = fam;

      await _api.requestVisit(widget.elderId, body);
      _snack('Visit requested ✅ (pending approval)');
      _refreshAll();
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  // ---------------- UI helpers ----------------

  Widget _errorCard(String title, Object err, VoidCallback retry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(err.toString(), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '-';
    try {
      final dt = DateTime.parse(v.toString());
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return v.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 9,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Elder #${widget.elderId}'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Health'),
              Tab(text: 'Meds'),
              Tab(text: 'Summary'),
              Tab(text: 'Incidents'),
              Tab(text: 'Location'),
              Tab(text: 'Visits'),
              Tab(text: 'Family'),
              Tab(text: 'Alerts'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh),
            )
          ],
        ),
        body: TabBarView(
          children: [
            // 1) Overview
            FutureBuilder<Map<String, dynamic>>(
              key: ValueKey('overview_$_reload'),
              future: _loadOverview(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: _errorCard('Failed to load overview', snap.error!, _refreshAll));
                }

                final elder = (snap.data?['elder'] as Map<String, dynamic>?) ?? {};
                final status = (snap.data?['status'] as Map<String, dynamic>?) ?? {};

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: cs.secondaryContainer,
                              foregroundColor: cs.onSecondaryContainer,
                              child: Text(((elder['name'] ?? 'E').toString()).substring(0, 1).toUpperCase()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((elder['name'] ?? 'Unknown').toString(),
                                      style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 6),
                                  Text('Age: ${elder['age'] ?? '-'} • Gender: ${elder['gender'] ?? '-'}'),
                                  Text('Last check-in: ${_fmtDate(elder['last_check_in'])}'),
                                ],
                              ),
                            ),
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
                            const SizedBox(height: 8),
                            Text('Last check-in time: ${_fmtDate(status['last_checkin_time'])}'),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () async {
                                try {
                                  await _api.checkInElder(widget.elderId);
                                  _snack('Check-in saved ✅');
                                  _refreshAll();
                                } catch (e) {
                                  _snack('Failed: $e');
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Check-in now'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // 2) Health
            _HealthTab(elderId: widget.elderId, reload: _reload, api: _api, onAdd: _dialogAddHealthLog, fmt: _fmtDate),

            // 3) Medications
_MedsTab(
  elderId: widget.elderId,
  reload: _reload,
  api: _api,
  fmt: _fmtDate,
  onChanged: _refreshAll,
),

            // 4) Summary
            _SummaryTab(elderId: widget.elderId, reload: _reload, api: _api, onEdit: _dialogEditDailySummary),

            // 5) Incidents
            _IncidentsTab(reload: _reload, onCreate: _dialogCreateIncident),

            // 6) Location
            _LocationTab(elderId: widget.elderId, reload: _reload, api: _api, onAdd: _dialogAddLocation, fmt: _fmtDate),

            // 7) Visits
            _VisitsTab(elderId: widget.elderId, reload: _reload, api: _api, onRequest: _dialogRequestVisit, fmt: _fmtDate),

            // 8) Family
            _FamilyTab(elderId: widget.elderId, reload: _reload, api: _api),

            // 9) Alerts
            _AlertsTab(elderId: widget.elderId, reload: _reload, api: _api, fmt: _fmtDate),
          ],
        ),
      ),
    );
  }
}

// ---------------- Tabs widgets (kept in same file) ----------------

class _HealthTab extends StatefulWidget {
  final int elderId;
  final int reload;
  final CaregiverApi api;
  final Future<void> Function() onAdd;
  final String Function(dynamic) fmt;

  const _HealthTab({
    required this.elderId,
    required this.reload,
    required this.api,
    required this.onAdd,
    required this.fmt,
  });

  @override
  State<_HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<_HealthTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('health_${widget.reload}'),
      future: widget.api.getElderHealthLogs(widget.elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Failed: ${snap.error}'));
        }
        final logs = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: Text('Health logs', style: Theme.of(context).textTheme.titleMedium)),
                FilledButton.icon(
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No health logs yet.'))),
            for (final l in logs)
              Card(
                child: ListTile(
                  title: Text(widget.fmt(l['date'])),
                  subtitle: Text(
                    'BP: ${l['blood_pressure'] ?? '-'} | Sugar: ${l['blood_sugar'] ?? '-'} | Temp: ${l['temperature'] ?? '-'}\nNotes: ${l['notes'] ?? '-'}',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MedsTab extends StatefulWidget {
  final int elderId;
  final int reload;
  final CaregiverApi api;
  final String Function(dynamic) fmt;
  final VoidCallback onChanged;

  const _MedsTab({
    required this.elderId,
    required this.reload,
    required this.api,
    required this.fmt,
    required this.onChanged,
  });

  @override
  State<_MedsTab> createState() => _MedsTabState();
}

class _MedsTabState extends State<_MedsTab> {
  String? _date; // YYYY-MM-DD
  int _days = 7;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _logStatus(Map<String, dynamic> item, String status) async {
    final notes = TextEditingController();
    final scheduled = TextEditingController(text: (item['scheduled_time'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark as $status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${item['name'] ?? '-'} • ${item['dosage'] ?? '-'}'),
            const SizedBox(height: 12),
            TextField(
              controller: scheduled,
              decoration: const InputDecoration(
                labelText: 'Scheduled time (optional)',
                hintText: 'YYYY-MM-DD HH:mm:ss',
              ),
            ),
            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    final medId = int.tryParse((item['medication_id'] ?? '').toString());
    if (medId == null) {
      _snack('Missing medication_id from API response');
      return;
    }

    try {
      await widget.api.logMedicationStatus(
        widget.elderId,
        medicationId: medId,
        status: status,
        scheduledTime: scheduled.text.trim().isEmpty ? null : scheduled.text.trim(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      );
      _snack('Medication logged ✅');
      widget.onChanged();
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Plan
        Text('Medication plan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          key: ValueKey('plan_${widget.reload}'),
          future: widget.api.getElderMedicationPlan(widget.elderId),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
            if (snap.hasError) return Text('Failed: ${snap.error}');
            final meds = snap.data ?? [];
            if (meds.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No active meds.')));
            return Column(
              children: meds.map((m) {
                return Card(
                  child: ListTile(
                    title: Text('${m['name'] ?? '-'} • ${m['dosage'] ?? '-'}'),
                    subtitle: Text('Freq: ${m['frequency'] ?? '-'}\n${m['instructions'] ?? ''}'),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 16),

        // Today checklist + ACTIONS ✅
        Text('Today checklist', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          key: ValueKey('check_${widget.reload}'),
          future: widget.api.getTodayMedicationChecklist(widget.elderId),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
            if (snap.hasError) return Text('Failed: ${snap.error}');
            final list = snap.data ?? [];
            if (list.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No checklist items.')));

            return Column(
              children: list.map((x) {
                final status = (x['today_status'] ?? x['status'] ?? 'pending').toString();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('${x['name'] ?? '-'} • ${x['dosage'] ?? '-'}'),
                          subtitle: Text('Status: $status • ${widget.fmt(x['today_taken_at'] ?? x['taken_at'])}'),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _logStatus(x, 'taken'),
                                icon: const Icon(Icons.check),
                                label: const Text('Taken'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _logStatus(x, 'missed'),
                                child: const Text('Missed'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _logStatus(x, 'skipped'),
                                child: const Text('Skipped'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 16),

        // Logs filter
        Row(
          children: [
            Expanded(child: Text('Medication logs', style: Theme.of(context).textTheme.titleMedium)),
            TextButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1),
                  initialDate: now,
                );
                if (picked == null) return;
                setState(() => _date = DateFormat('yyyy-MM-dd').format(picked));
              },
              child: Text(_date == null ? 'Pick date' : _date!),
            ),
            if (_date != null)
              IconButton(
                tooltip: 'Clear',
                onPressed: () => setState(() => _date = null),
                icon: const Icon(Icons.clear),
              ),
          ],
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          key: ValueKey('logs_${widget.reload}_${_date ?? 'all'}'),
          future: widget.api.getMedicationLogs(widget.elderId, date: _date),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
            if (snap.hasError) return Text('Failed: ${snap.error}');
            final logs = snap.data ?? [];
            if (logs.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No logs.')));
            return Column(
              children: logs.map((l) {
                return Card(
                  child: ListTile(
                    title: Text('${l['name'] ?? '-'} • ${l['dosage'] ?? '-'}'),
                    subtitle: Text('Status: ${l['status'] ?? '-'} • Taken: ${widget.fmt(l['taken_at'])}\n${l['notes'] ?? ''}'),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 16),

        // Stats
        Row(
          children: [
            Expanded(child: Text('Stats', style: Theme.of(context).textTheme.titleMedium)),
            DropdownButton<int>(
              value: _days,
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 days')),
                DropdownMenuItem(value: 14, child: Text('14 days')),
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 60, child: Text('60 days')),
              ],
              onChanged: (v) => setState(() => _days = v ?? 7),
            ),
          ],
        ),
        FutureBuilder<Map<String, dynamic>>(
          key: ValueKey('stats_${widget.reload}_$_days'),
          future: widget.api.getMedicationStats(widget.elderId, days: _days),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
            if (snap.hasError) return Text('Failed: ${snap.error}');
            final data = snap.data ?? {};
            final summary = (data['summary'] as Map?) ?? {};
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Taken: ${summary['taken_count'] ?? 0} • Missed: ${summary['missed_count'] ?? 0} • '
                  'Skipped: ${summary['skipped_count'] ?? 0}\nAdherence: ${summary['adherence_percent'] ?? '-'}%',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}


class _SummaryTab extends StatelessWidget {
  final int elderId;
  final int reload;
  final CaregiverApi api;
  final Future<void> Function(Map<String, dynamic>? existing) onEdit;

  const _SummaryTab({required this.elderId, required this.reload, required this.api, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey('summary_$reload'),
      future: api.getDailySummary(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Failed: ${snap.error}'));
        }

        final s = snap.data;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: Text('Today summary', style: Theme.of(context).textTheme.titleMedium)),
                FilledButton.icon(
                  onPressed: () => onEdit(s),
                  icon: const Icon(Icons.edit),
                  label: Text(s == null ? 'Create' : 'Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: s == null
                    ? const Text('No summary for today yet.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mood: ${s['mood'] ?? '-'}'),
                          Text('Meals: ${s['meals'] ?? '-'}'),
                          Text('Activities: ${s['activities'] ?? '-'}'),
                          Text('Medication taken: ${s['medication_taken'] == 1 ? 'Yes' : s['medication_taken'] == 0 ? 'No' : 'Unknown'}'),
                          Text('Sleep hours: ${s['sleep_hours'] ?? '-'}'),
                          const SizedBox(height: 8),
                          Text('Notes:\n${s['notes'] ?? '-'}'),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IncidentsTab extends StatelessWidget {
  final int reload;
  final Future<void> Function() onCreate;

  const _IncidentsTab({required this.reload, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text('Incidents', style: Theme.of(context).textTheme.titleMedium)),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create')),
          ],
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'This tab creates a new incident for this elder.\n'
              'For incident history/details, use the global Incidents page.',
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationTab extends StatelessWidget {
  final int elderId;
  final int reload;
  final CaregiverApi api;
  final Future<void> Function() onAdd;
  final String Function(dynamic) fmt;

  const _LocationTab({
    required this.elderId,
    required this.reload,
    required this.api,
    required this.onAdd,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('loc_$reload'),
      future: api.getElderLocationHistory(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Center(child: Text('Failed: ${snap.error}'));

        final items = snap.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: Text('Location history', style: Theme.of(context).textTheme.titleMedium)),
                FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_location_alt_outlined), label: const Text('Add')),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No location history.'))),
            for (final x in items)
              Card(
                child: ListTile(
                  title: Text('${x['latitude'] ?? '-'}, ${x['longitude'] ?? '-'}'),
                  subtitle: Text('Recorded: ${fmt(x['recorded_at'])}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VisitsTab extends StatelessWidget {
  final int elderId;
  final int reload;
  final CaregiverApi api;
  final Future<void> Function() onRequest;
  final String Function(dynamic) fmt;

  const _VisitsTab({
    required this.elderId,
    required this.reload,
    required this.api,
    required this.onRequest,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('vis_$reload'),
      future: api.getElderUpcomingVisits(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Failed: ${snap.error}'));

        final visits = snap.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: Text('Upcoming visits', style: Theme.of(context).textTheme.titleMedium)),
                FilledButton.icon(onPressed: onRequest, icon: const Icon(Icons.add), label: const Text('Request')),
              ],
            ),
            const SizedBox(height: 12),
            if (visits.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No upcoming visits.'))),
            for (final v in visits)
              Card(
                child: ListTile(
                  title: Text('Scheduled: ${fmt(v['scheduled_at'])} • ${v['duration_minutes'] ?? '-'} min'),
                  subtitle: Text('Status: ${v['status'] ?? '-'}\n${v['notes'] ?? ''}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FamilyTab extends StatelessWidget {
  final int elderId;
  final int reload;
  final CaregiverApi api;

  const _FamilyTab({required this.elderId, required this.reload, required this.api});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('fam_$reload'),
      future: api.getElderFamilyContacts(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Failed: ${snap.error}'));

        final fam = snap.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Family contacts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (fam.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No family contacts found.'))),
            for (final f in fam)
              Card(
                child: ListTile(
                  title: Text('${f['name'] ?? '-'} (${f['relation'] ?? '-'})'),
                  subtitle: Text('Phone: ${f['phone'] ?? '-'}\nEmail: ${f['email'] ?? '-'}'),
                  trailing: (f['is_primary'] == 1) ? const Icon(Icons.star, size: 18) : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AlertsTab extends StatelessWidget {
  final int elderId;
  final int reload;
  final CaregiverApi api;
  final String Function(dynamic) fmt;

  const _AlertsTab({required this.elderId, required this.reload, required this.api, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('al_$reload'),
      future: api.getElderAlerts(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Failed: ${snap.error}'));

        final alerts = snap.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Open alerts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No open alerts.'))),
            for (final a in alerts)
              Card(
                child: ListTile(
                  title: Text((a['message'] ?? '').toString().isEmpty ? 'Alert' : (a['message'] ?? 'Alert').toString()),
                  subtitle: Text('Type: ${a['type'] ?? '-'} • Created: ${fmt(a['created_at'])}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Text((a['severity'] ?? 'medium').toString(), style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

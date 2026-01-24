import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/caregiver_api.dart';
import 'package:geolocator/geolocator.dart'; // ✅ Package integrated
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<Map<String, dynamic>> _loadOverview() async {
    final elder = await _api.getElderDetails(widget.elderId);
    final status = await _api.getElderStatus(widget.elderId);
    return {'elder': elder, 'status': status};
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '-';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return v.toString();
    }
  }

  // ---------------- Automated Location Logic ----------------

  Future<void> _handleUpdateLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _snack('Location services are disabled. Please enable GPS.');
      return;
    }

    // 2. Handle permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _snack('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _snack('Location permissions are permanently denied. Check settings.');
      return;
    }

    _snack('Fetching current GPS coordinates...');

    try {
      // 3. Get actual position
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 4. Send to API
      await _api.updateElderLocation(
        widget.elderId, 
        latitude: pos.latitude, 
        longitude: pos.longitude
      );

      _snack('Location verified & saved ✅');
      _refreshAll(); 
    } catch (e) {
      _snack('Error capturing location: $e');
    }
  }

  // ---------------- Dialog Handlers ----------------

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
    } catch (e) { _snack('Failed: $e'); }
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
    } catch (e) { _snack('Failed: $e'); }
  }

  Future<void> _dialogCreateIncident() async {
    final type = TextEditingController();
    final severity = ValueNotifier<String>('medium');
    final title = TextEditingController();
    final desc = TextEditingController();
    final occurredAt = TextEditingController();

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
              TextField(controller: occurredAt, decoration: const InputDecoration(labelText: 'Occurred at (YYYY-MM-DD HH:mm:ss)')),
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
    } catch (e) { _snack('Failed: $e'); }
  }

  Future<void> _dialogRequestVisit() async {
    final scheduledAt = TextEditingController();
    final duration = TextEditingController(text: '30');
    final notes = TextEditingController();
    final familyId = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request visit'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: scheduledAt, decoration: const InputDecoration(labelText: 'Scheduled at (YYYY-MM-DD HH:mm:ss)')),
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
    if (scheduledAt.text.trim().isEmpty || dur == null) { _snack('Missing required fields'); return; }
    try {
      final body = <String, dynamic>{
        'scheduled_at': scheduledAt.text.trim(),
        'duration_minutes': dur,
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      };
      final fam = int.tryParse(familyId.text.trim());
      if (fam != null) body['family_id'] = fam;
      await _api.requestVisit(widget.elderId, body);
      _snack('Visit requested ✅');
      _refreshAll();
    } catch (e) { _snack('Failed: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 9,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F4),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('Elder Profile', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(onPressed: _refreshAll, icon: const Icon(Icons.sync_rounded)),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: cs.primary,
            labelColor: cs.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Overview'), Tab(text: 'Health'), Tab(text: 'Meds'),
              Tab(text: 'Summary'), Tab(text: 'Incidents'), Tab(text: 'Location'),
              Tab(text: 'Visits'), Tab(text: 'Family'), Tab(text: 'Alerts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(cs, tt),
            _HealthTab(elderId: widget.elderId, reload: _reload, api: _api, onAdd: _dialogAddHealthLog, fmt: _fmtDate),
            _MedsTab(elderId: widget.elderId, reload: _reload, api: _api, fmt: _fmtDate, onChanged: _refreshAll),
            _SummaryTab(elderId: widget.elderId, reload: _reload, api: _api, onEdit: _dialogEditDailySummary),
            _IncidentsTab(elderId: widget.elderId, reload: _reload, api: _api, fmt: _fmtDate, onCreate: _dialogCreateIncident),
            _LocationTab(elderId: widget.elderId, reload: _reload, api: _api, onUpdate: _handleUpdateLocation, fmt: _fmtDate),
            _VisitsTab(elderId: widget.elderId, reload: _reload, api: _api, onRequest: _dialogRequestVisit, fmt: _fmtDate),
            _FamilyTab(elderId: widget.elderId, reload: _reload, api: _api),
            _AlertsTab(elderId: widget.elderId, reload: _reload, api: _api, fmt: _fmtDate),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(ColorScheme cs, TextTheme tt) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey('overview_$_reload'),
      future: _loadOverview(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final elder = snap.data!['elder'] ?? {};
        final status = snap.data!['status'] ?? {};
        final name = elder['name'] ?? 'Resident';

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: cs.primaryContainer,
                    child: Text(name[0].toUpperCase(), style: tt.headlineMedium?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Age: ${elder['age'] ?? '-'} • ${elder['gender'] ?? '-'}', style: tt.bodyMedium?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text('Last Check-in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_fmtDate(status['last_checkin_time']), style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          await _api.checkInElder(widget.elderId);
                          _snack('Check-in saved ✅');
                          _refreshAll();
                        } catch (e) { _snack('Failed: $e'); }
                      },
                      icon: const Icon(Icons.touch_app),
                      label: const Text('Perform Check-in Now'),
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------- Tabs widgets (Optimized) ----------------

class _HealthTab extends StatelessWidget {
  final int elderId, reload;
  final CaregiverApi api;
  final Future<void> Function() onAdd;
  final String Function(dynamic) fmt;
  const _HealthTab({required this.elderId, required this.reload, required this.api, required this.onAdd, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('health_$reload'),
      future: api.getElderHealthLogs(elderId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final logs = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Health Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton.filledTonal(onPressed: onAdd, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No logs recorded.'))),
            ...logs.map((l) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fmt(l['date']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _vital(Icons.favorite, 'BP', l['blood_pressure'], Colors.red),
                      _vital(Icons.water_drop, 'Sugar', l['blood_sugar'], Colors.orange),
                      _vital(Icons.thermostat, 'Temp', l['temperature'], Colors.blue),
                      _vital(Icons.monitor_heart, 'HR', l['heart_rate'], Colors.green),
                    ],
                  ),
                  if (l['notes'] != null) Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l['notes'], style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                  )
                ],
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _vital(IconData icon, String label, dynamic val, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        Text(label, style: const TextStyle(fontSize: 10)),
        Text(val?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _MedsTab extends StatefulWidget {
  final int elderId, reload;
  final CaregiverApi api;
  final String Function(dynamic) fmt;
  final VoidCallback onChanged;
  const _MedsTab({required this.elderId, required this.reload, required this.api, required this.fmt, required this.onChanged});

  @override
  State<_MedsTab> createState() => _MedsTabState();
}

class _MedsTabState extends State<_MedsTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Medication Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          key: ValueKey('plan_${widget.reload}'),
          future: widget.api.getElderMedicationPlan(widget.elderId),
          builder: (context, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            final meds = snap.data!;
            return Column(children: meds.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${m['name']} • ${m['dosage']}'),
                subtitle: Text('Freq: ${m['frequency']}\nInstr: ${m['instructions'] ?? '-'}'),
              ),
            )).toList());
          },
        ),
        const SizedBox(height: 24),
        const Text('Today Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          key: ValueKey('check_${widget.reload}'),
          future: widget.api.getTodayMedicationChecklist(widget.elderId),
          builder: (context, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            final list = snap.data!;
            return Column(children: list.map((x) {
              final status = (x['today_status'] ?? x['status'] ?? 'pending').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(status == 'taken' ? Icons.check_circle : Icons.pending, color: status == 'taken' ? Colors.green : Colors.orange),
                      title: Text('${x['name']} • ${x['dosage']}'),
                      subtitle: Text('Status: $status • ${widget.fmt(x['today_taken_at'] ?? x['taken_at'])}'),
                    ),
                    if (status != 'taken') Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(onPressed: () => _log(x, 'taken'), child: const Text('Taken')),
                        TextButton(onPressed: () => _log(x, 'missed'), child: const Text('Missed', style: TextStyle(color: Colors.red))),
                        TextButton(onPressed: () => _log(x, 'skipped'), child: const Text('Skipped', style: TextStyle(color: Colors.grey))),
                      ],
                    )
                  ],
                ),
              );
            }).toList());
          },
        ),
      ],
    );
  }

  Future<void> _log(Map<String, dynamic> item, String status) async {
    final medId = int.tryParse(item['medication_id'].toString());
    if (medId == null) return;
    try {
      await widget.api.logMedicationStatus(widget.elderId, medicationId: medId, status: status);
      widget.onChanged();
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }
}

class _SummaryTab extends StatelessWidget {
  final int elderId, reload;
  final CaregiverApi api;
  final Future<void> Function(Map<String, dynamic>? existing) onEdit;
  const _SummaryTab({required this.elderId, required this.reload, required this.api, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey('summary_$reload'),
      future: api.getDailySummary(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final s = snap.data;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Today Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                FilledButton.icon(onPressed: () => onEdit(s), icon: const Icon(Icons.edit), label: Text(s == null ? 'Create' : 'Edit')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: s == null ? const Text('No entry for today.') : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow('Mood', s['mood']),
                  _summaryRow('Meals', s['meals']),
                  _summaryRow('Activities', s['activities']),
                  _summaryRow('Medication', s['medication_taken'] == 1 ? 'Yes' : 'No'),
                  _summaryRow('Sleep', '${s['sleep_hours'] ?? '-'} hrs'),
                  const Divider(height: 32),
                  const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(s['notes'] ?? '-', style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryRow(String label, dynamic val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(val?.toString() ?? '-'),
      ]),
    );
  }
}

class _IncidentsTab extends StatelessWidget {
  final int elderId, reload;
  final CaregiverApi api;
  final String Function(dynamic) fmt;
  final Future<void> Function() onCreate;

  const _IncidentsTab({required this.elderId, required this.reload, required this.api, required this.fmt, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('inc_$reload'),
      future: api.getMyIncidents(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final all = snap.data ?? [];
        final incidents = all.where((x) => x['elder_id'] == elderId).toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Incidents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create')),
              ],
            ),
            const SizedBox(height: 12),
            if (incidents.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No incidents recorded.'))),
            ...incidents.map((i) => Card(
              child: ListTile(
                title: Text(i['title'] ?? 'Incident'),
                subtitle: Text('Type: ${i['type']} • Severity: ${i['severity']} • Occurred: ${fmt(i['occurred_at'])}\n${i['description'] ?? ""}'),
              ),
            )),
          ],
        );
      },
    );
  }
}

class _LocationTab extends StatefulWidget {
  final int elderId, reload;
  final CaregiverApi api;
  final VoidCallback onUpdate;
  final String Function(dynamic) fmt;

  const _LocationTab({required this.elderId, required this.reload, required this.api, required this.onUpdate, required this.fmt});

  @override
  State<_LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<_LocationTab> {
  // Default position if no history exists
  LatLng _mapCenter = const LatLng(32.2240, 35.2616); 

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('loc_${widget.reload}'),
      future: widget.api.getElderLocationHistory(widget.elderId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;

        // Update center to the latest recorded location if history exists
        if (items.isNotEmpty) {
          _mapCenter = LatLng(
            double.parse(items.first['latitude'].toString()),
            double.parse(items.first['longitude'].toString()),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(child: Text('Location History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                FilledButton.icon(
                  onPressed: widget.onUpdate,
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Verify My Location'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🗺️ THIS IS THE MISSING WIDGET
            Container(
              height: 300, // Important: Map must have a defined height on Web
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 15),
                  markers: {
                    Marker(markerId: const MarkerId('current'), position: _mapCenter),
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
            ...items.map((x) => Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.redAccent),
                title: Text('Lat: ${x['latitude']}, Lng: ${x['longitude']}'),
                subtitle: Text('Recorded: ${widget.fmt(x['recorded_at'])}'),
              ),
            )),
          ],
        );
      },
    );
  }
}

class _VisitsTab extends StatelessWidget {
  final int elderId, reload;
  final CaregiverApi api;
  final Future<void> Function() onRequest;
  final String Function(dynamic) fmt;
  const _VisitsTab({required this.elderId, required this.reload, required this.api, required this.onRequest, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('vis_$reload'),
      future: api.getElderUpcomingVisits(elderId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final visits = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Upcoming Visits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                FilledButton.icon(onPressed: onRequest, icon: const Icon(Icons.calendar_month), label: const Text('Request')),
              ],
            ),
            const SizedBox(height: 12),
            if (visits.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No upcoming visits.'))),
            ...visits.map((v) => Card(child: ListTile(
              title: Text('${fmt(v['scheduled_at'])} (${v['duration_minutes']} min)'),
              subtitle: Text('Status: ${v['status']}\nNotes: ${v['notes'] ?? '-'}'),
            ))),
          ],
        );
      },
    );
  }
}

class _FamilyTab extends StatelessWidget {
  final int elderId, reload;
  final CaregiverApi api;
  const _FamilyTab({required this.elderId, required this.reload, required this.api});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('fam_$reload'),
      future: api.getElderFamilyContacts(elderId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final fam = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Family Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ...fam.map((f) => Card(child: ListTile(
              leading: Icon(f['is_primary'] == 1 ? Icons.star : Icons.person, color: f['is_primary'] == 1 ? Colors.orange : null),
              title: Text('${f['name']} (${f['relation']})'),
              subtitle: Text('Phone: ${f['phone']}\nEmail: ${f['email']}'),
            ))),
          ],
        );
      },
    );
  }
}

class _AlertsTab extends StatelessWidget {
  final int elderId, reload;
  final CaregiverApi api;
  final String Function(dynamic) fmt;

  // 🎨 Palette Constants
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  const _AlertsTab({required this.elderId, required this.reload, required this.api, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('al_$reload'),
      future: api.getElderEmergencyRequests(elderId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _deepNavy));
        final alerts = snap.data!;

        return ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const Text('Urgent Alerts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: _deepNavy, letterSpacing: -0.5)),
            const SizedBox(height: 16),
            if (alerts.isEmpty) 
              _buildEmptyState()
            else 
              ...alerts.map((a) => _buildEmergencyBento(a)),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyBento(Map<String, dynamic> a) {
    final severity = (a['severity'] ?? 'critical').toString().toLowerCase();
    final Color sevColor = severity == 'critical' ? Colors.redAccent : _sage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🚨 Emergency Indicator Pulse
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: sevColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.emergency_share_rounded, color: sevColor, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (a['emergency_type'] ?? 'SOS').toString().toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: sevColor, letterSpacing: 1.2),
                      ),
                      Text(fmt(a['created_at']), style: const TextStyle(color: _denim, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Using 'description' or 'address_text' to reduce ambiguity
                  Text(
                    a['description'] ?? a['message'] ?? 'No specific details provided',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _deepNavy, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  if (a['address_text'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: _denim),
                        const SizedBox(width: 4),
                        Expanded(child: Text(a['address_text'], style: const TextStyle(color: _denim, fontSize: 12))),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: const Center(child: Text('All systems normal. No active alerts.', style: TextStyle(color: _denim, fontStyle: FontStyle.italic))),
    );
  }
}
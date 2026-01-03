import 'package:flutter/material.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/services/dio_factory.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class ElderDetailsPage extends StatefulWidget {
  final int elderId;
  const ElderDetailsPage({super.key, required this.elderId});

  @override
  State<ElderDetailsPage> createState() => _ElderDetailsPageState();
}

class _ElderDetailsPageState extends State<ElderDetailsPage> {
  late final RetirementHomeApi api;

  @override
  void initState() {
    super.initState();
    api = RetirementHomeApi(DioFactory.create());
  }

  Future<void> _checkInOut(bool checkIn) async {
    try {
      if (checkIn) {
        await api.checkInElder(widget.elderId);
      } else {
        await api.checkOutElder(widget.elderId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(checkIn ? 'Checked in ✅' : 'Checked out ✅')),
        );
        setState(() {}); // refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RetirementHomeLayout(
      title: 'Elder details',
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _checkInOut(true),
                  child: const Text('Check-in'),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => _checkInOut(false),
                  child: const Text('Check-out'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Health logs'),
                Tab(text: 'Location'),
                Tab(text: 'Attendance'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(api: api, elderId: widget.elderId),
                  _HealthLogsTab(api: api, elderId: widget.elderId),
                  _LocationTab(api: api, elderId: widget.elderId),
                  _AttendanceTab(api: api, elderId: widget.elderId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final RetirementHomeApi api;
  final int elderId;

  const _OverviewTab({required this.api, required this.elderId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.getElderDetails(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

        final e = snap.data ?? {};
        return ListView(
          children: [
            ListTile(title: const Text('Name'), subtitle: Text('${e['name'] ?? '-'}')),
            ListTile(title: const Text('Age'), subtitle: Text('${e['age'] ?? '-'}')),
            ListTile(title: const Text('Gender'), subtitle: Text('${e['gender'] ?? '-'}')),
            ListTile(title: const Text('Assigned caregiver'), subtitle: Text('${e['caregiver_name'] ?? '-'}')),
            ListTile(title: const Text('Last check-in'), subtitle: Text('${e['last_check_in'] ?? '-'}')),
            const Divider(),
            ListTile(title: const Text('Latest BP'), subtitle: Text('${e['blood_pressure'] ?? '-'}')),
            ListTile(title: const Text('Latest Sugar'), subtitle: Text('${e['blood_sugar'] ?? '-'}')),
            ListTile(title: const Text('Latest Temp'), subtitle: Text('${e['temperature'] ?? '-'}')),
          ],
        );
      },
    );
  }
}

class _HealthLogsTab extends StatelessWidget {
  final RetirementHomeApi api;
  final int elderId;

  const _HealthLogsTab({required this.api, required this.elderId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: api.getElderHealthLogs(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

        final logs = snap.data ?? [];
        if (logs.isEmpty) return const Center(child: Text('No logs found.'));
        return ListView.separated(
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final l = logs[i];
            return ListTile(
              title: Text('${l['date'] ?? ''}'),
              subtitle: Text(
                'BP: ${l['blood_pressure'] ?? '-'} | Sugar: ${l['blood_sugar'] ?? '-'} | Temp: ${l['temperature'] ?? '-'}\nNotes: ${l['notes'] ?? '-'}',
              ),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}

class _LocationTab extends StatelessWidget {
  final RetirementHomeApi api;
  final int elderId;

  const _LocationTab({required this.api, required this.elderId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: api.getElderLocationHistory(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

        final history = snap.data ?? [];
        if (history.isEmpty) return const Center(child: Text('No location history.'));
        return ListView.separated(
          itemCount: history.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final h = history[i];
            return ListTile(
              title: Text('${h['recorded_at'] ?? ''}'),
              subtitle: Text('Lat: ${h['latitude'] ?? '-'} | Lng: ${h['longitude'] ?? '-'}'),
            );
          },
        );
      },
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final RetirementHomeApi api;
  final int elderId;

  const _AttendanceTab({required this.api, required this.elderId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: api.getElderAttendance(elderId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

        final list = snap.data ?? [];
        if (list.isEmpty) return const Center(child: Text('No attendance history.'));
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = list[i];
            return ListTile(
              title: Text('${a['action'] ?? '-'}'),
              subtitle: Text('${a['created_at'] ?? '-'}\nNotes: ${a['notes'] ?? '-'}'),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}

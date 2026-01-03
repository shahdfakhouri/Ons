import 'package:flutter/material.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/services/dio_factory.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class CenterPage extends StatefulWidget {
  const CenterPage({super.key});

  @override
  State<CenterPage> createState() => _CenterPageState();
}

class _CenterPageState extends State<CenterPage> {
  late final RetirementHomeApi api;

  @override
  void initState() {
    super.initState();
    api = RetirementHomeApi(DioFactory.create());
  }

  @override
  Widget build(BuildContext context) {
    return RetirementHomeLayout(
      title: 'Center',
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Alerts'),
                Tab(text: 'Incidents'),
                Tab(text: 'Emergencies'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _AlertsTab(api: api),
                  _IncidentsTab(api: api),
                  _EmergenciesTab(api: api),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  final RetirementHomeApi api;
  const _AlertsTab({required this.api});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: api.getAlerts(status: 'open'),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        final alerts = (snap.data as List<Map<String, dynamic>>?) ?? [];
        if (alerts.isEmpty) return const Center(child: Text('No alerts.'));

        return ListView.separated(
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = alerts[i];
            return ListTile(
              title: Text('${a['type'] ?? 'Alert'} - ${a['severity'] ?? ''}'),
              subtitle: Text('${a['message'] ?? ''}\nElder: ${a['elder_name'] ?? '-'}\n${a['created_at'] ?? ''}'),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}

class _IncidentsTab extends StatefulWidget {
  final RetirementHomeApi api;
  const _IncidentsTab({required this.api});

  @override
  State<_IncidentsTab> createState() => _IncidentsTabState();
}

class _IncidentsTabState extends State<_IncidentsTab> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButton<String>(
            value: filter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'open', child: Text('Open')),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              DropdownMenuItem(value: 'investigating', child: Text('Investigating')),
            ],
            onChanged: (v) => setState(() => filter = v ?? 'all'),
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: widget.api.getIncidents(status: filter),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

              final incidents = (snap.data as List<Map<String, dynamic>>?) ?? [];
              if (incidents.isEmpty) return const Center(child: Text('No incidents.'));

              return ListView.separated(
                itemCount: incidents.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final inc = incidents[i];
                  final id = int.tryParse(inc['incident_id'].toString()) ?? 0;

                  return ListTile(
                    title: Text('${inc['type'] ?? 'Incident'} - ${inc['severity'] ?? ''}'),
                    subtitle: Text(
                      'Status: ${inc['status'] ?? ''}\nElder: ${inc['elder_name'] ?? '-'}\n${inc['created_at'] ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (status) async {
                        await widget.api.updateIncidentStatus(id, status);
                        setState(() {});
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'open', child: Text('Mark open')),
                        PopupMenuItem(value: 'investigating', child: Text('Mark investigating')),
                        PopupMenuItem(value: 'resolved', child: Text('Mark resolved')),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmergenciesTab extends StatelessWidget {
  final RetirementHomeApi api;
  const _EmergenciesTab({required this.api});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: api.getEmergencies(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

        final list = (snap.data as List<Map<String, dynamic>>?) ?? [];
        if (list.isEmpty) return const Center(child: Text('No emergencies.'));

        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = list[i];
            final id = int.tryParse(e['emergency_id'].toString()) ?? 0;

            return ListTile(
              title: Text('${e['type'] ?? 'Emergency'}'),
              subtitle: Text('Status: ${e['status'] ?? ''}\n${e['created_at'] ?? ''}'),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => api.rejectEmergency(id),
                    child: const Text('Reject'),
                  ),
                  ElevatedButton(
                    onPressed: () => api.acceptEmergency(id),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

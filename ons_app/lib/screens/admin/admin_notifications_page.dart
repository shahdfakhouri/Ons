import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_notifications_api.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage>
    with SingleTickerProviderStateMixin {
  final AdminNotificationsApi api = AdminNotificationsApi();

  late TabController tabs;

  bool loading = true;
  String? error;

  String healthStatus = 'open'; // open | resolved | all
  List<Map<String, dynamic>> healthAlerts = [];
  List<Map<String, dynamic>> allNotifications = [];

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final alerts = await api.getHealthAlerts(status: healthStatus);
      final all = await api.getAdminNotifications();

      setState(() {
        healthAlerts = alerts;
        allNotifications = all;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  int _asInt(dynamic x) => int.tryParse('${x ?? ''}') ?? 0;
  bool _asBool(dynamic x) => x == true || x == 1 || '$x' == 'true';

  Future<void> _markRead(int id) async {
    await api.markAsRead(id);
    await _loadAll();
  }

  Future<void> _resolve(int id) async {
    await api.resolveAlert(id);
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Notifications',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadAll,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loadAll,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                        const SizedBox(width: 12),
                        if (tabs.index == 0) ...[
                          const Text('Status: '),
                          DropdownButton<String>(
                            value: healthStatus,
                            items: const [
                              DropdownMenuItem(value: 'open', child: Text('open')),
                              DropdownMenuItem(value: 'resolved', child: Text('resolved')),
                              DropdownMenuItem(value: 'all', child: Text('all')),
                            ],
                            onChanged: (v) async {
                              if (v == null) return;
                              setState(() => healthStatus = v);
                              await _loadAll();
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    TabBar(
                      controller: tabs,
                      onTap: (_) => setState(() {}),
                      tabs: const [
                        Tab(text: 'Health Alerts'),
                        Tab(text: 'All Notifications'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: TabBarView(
                        controller: tabs,
                        children: [
                          _buildHealthAlerts(),
                          _buildAllNotifications(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHealthAlerts() {
    if (healthAlerts.isEmpty) return const Center(child: Text('No health alerts'));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: healthAlerts.length,
      itemBuilder: (_, i) {
        final a = healthAlerts[i];
        final id = _asInt(a['id']);
        final msg = (a['message'] ?? '').toString();
        final created = (a['created_at'] ?? '').toString();
        final status = (a['status'] ?? '').toString();
        final severity = (a['severity'] ?? '').toString();
        final isRead = _asBool(a['is_read']);

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.health_and_safety,
              color: isRead ? Colors.grey : Colors.red,
            ),
            title: Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('severity: $severity\nstatus: $status\n$created'),
            isThreeLine: true,
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'Mark read',
                  onPressed: id == 0 ? null : () => _markRead(id),
                  icon: const Icon(Icons.mark_email_read),
                ),
                FilledButton(
                  onPressed: (id == 0 || status == 'resolved') ? null : () => _resolve(id),
                  child: const Text('Resolve'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllNotifications() {
    if (allNotifications.isEmpty) return const Center(child: Text('No notifications'));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: allNotifications.length,
      itemBuilder: (_, i) {
        final n = allNotifications[i];
        final id = _asInt(n['id']);
        final type = (n['type'] ?? '').toString();
        final msg = (n['message'] ?? '').toString();
        final created = (n['created_at'] ?? '').toString();
        final isRead = _asBool(n['is_read']);

        return Card(
          child: ListTile(
            leading: Icon(isRead ? Icons.notifications : Icons.notifications_active),
            title: Text('$type: $msg', maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(created),
            trailing: isRead
                ? const Icon(Icons.check, color: Colors.green)
                : FilledButton(
                    onPressed: id == 0 ? null : () => _markRead(id),
                    child: const Text('Mark read'),
                  ),
          ),
        );
      },
    );
  }
}

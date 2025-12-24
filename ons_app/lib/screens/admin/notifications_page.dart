import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AdminApi _api = AdminApi();

  bool _loading = true;
  String? _error;
  List _alerts = [];

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
      final rows = await _api.getHealthAlerts();
      setState(() {
        _alerts = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _alerts = [];
        _loading = false;
      });
    }
  }

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  bool _asBool(dynamic x) {
    if (x is bool) return x;
    if (x is int) return x == 1;
    return (x?.toString() ?? '').toLowerCase() == 'true';
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Notifications & Reports',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _load,
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
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Total: ${_alerts.length}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _alerts.isEmpty
                          ? const Center(child: Text('No notifications found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _alerts.length,
                              itemBuilder: (context, index) {
                                final a = _alerts[index] as Map;

                                final message = _v(a['message']);
                                final createdAt = _v(a['created_at']);
                                final isRead = _asBool(a['is_read']);

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.notification_important,
                                      color: isRead ? Colors.grey : Colors.red,
                                    ),
                                    title: Text(
                                      message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text('Created: $createdAt'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isRead ? Colors.grey : Colors.blue)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        isRead ? 'Read' : 'Unread',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isRead ? Colors.grey : Colors.blue,
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

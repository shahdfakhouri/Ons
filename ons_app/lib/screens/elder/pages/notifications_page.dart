import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_api.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      items = await api.elderNotifications();
      setState(() => loading = false);
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _markRead(dynamic e) async {
    final id = e['notification_id'] ?? e['id'];
    if (id == null) return;

    try {
      await api.markElderNotificationRead(int.parse('$id'));
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final e = items[i] as Map;
                final title = e['title']?.toString() ?? e['category']?.toString() ?? 'Notification';
                final msg = e['message']?.toString() ?? '';
                final read = e['is_read'] == true || e['is_read'] == 1;
                final date = e['created_at']?.toString() ?? '';

                return Card(
                  child: ListTile(
                    leading: Icon(read ? Icons.mark_email_read : Icons.mark_email_unread),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text([if (msg.isNotEmpty) msg, if (date.isNotEmpty) date].join('\n')),
                    trailing: read
                        ? const Icon(Icons.check, color: Colors.green)
                        : FilledButton(
                            onPressed: () => _markRead(e),
                            child: const Text('Read'),
                          ),
                  ),
                );
              },
            ),
    );
  }
}

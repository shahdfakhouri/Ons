import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_api.dart';

class NotificationsPage extends StatefulWidget {
  // ✅ 1. Accept the onBack navigation callback
  final void Function(int index)? onBack;
  const NotificationsPage({super.key, this.onBack});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  // ONS Signature Palette
  static const _deepNavy = Color(0xFF313647);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFF9F9F4);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ 2. Helper to return to Index 0 (Home)
  void _triggerBack() {
    if (widget.onBack != null) {
      widget.onBack!(0);
    }
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      items = await api.elderNotifications();
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
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
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: _deepNavy)));
    if (error != null) return Scaffold(body: Center(child: Text('Error: $error')));

    // ✅ 3. PopScope intercepts hardware/gesture back to stay in Layout
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          // ✅ 4. Manual back button to return to Elder Home (Index 0)
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _deepNavy),
            onPressed: _triggerBack,
          ),
          title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.bold, color: _deepNavy)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: _deepNavy))
          ],
        ),
        body: items.isEmpty
            ? const Center(child: Text('No new messages', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final e = items[i] as Map;
                  final title = e['title']?.toString() ?? e['category']?.toString() ?? 'Update';
                  final msg = e['message']?.toString() ?? '';
                  final read = e['is_read'] == true || e['is_read'] == 1;
                  final date = e['created_at']?.toString() ?? '';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: read ? Colors.transparent : _sage.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    color: read ? Colors.white : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: read ? _cream : _sage.withOpacity(0.2),
                        child: Icon(
                          read ? Icons.mail_outline : Icons.mail,
                          color: read ? Colors.grey : _sage,
                        ),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: read ? FontWeight.normal : FontWeight.w900,
                          color: _deepNavy,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.isNotEmpty) 
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(msg, style: TextStyle(color: Colors.grey.shade700)),
                            ),
                          if (date.isNotEmpty) 
                            Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      trailing: read
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                          : TextButton(
                              onPressed: () => _markRead(e),
                              style: TextButton.styleFrom(foregroundColor: _sage),
                              child: const Text('Mark Read', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
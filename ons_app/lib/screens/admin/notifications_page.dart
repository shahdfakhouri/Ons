import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Notifications & Reports',
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // dummy
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.notification_important),
              title: Text('Alert #${index + 1}'),
              subtitle: const Text('Dummy notification detail...'),
            ),
          );
        },
      ),
    );
  }
}

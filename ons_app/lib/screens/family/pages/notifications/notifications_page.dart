import 'package:flutter/material.dart';

class FamilyNotificationsPage extends StatefulWidget {
  const FamilyNotificationsPage({super.key});

  @override
  State<FamilyNotificationsPage> createState() => _FamilyNotificationsPageState();
}

class _FamilyNotificationsPageState extends State<FamilyNotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: const Center(
        child: Text('Notifications UI coming next ✅'),
      ),
    );
  }
}

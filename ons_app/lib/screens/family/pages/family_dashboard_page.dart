import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class FamilyDashboardPage extends StatefulWidget {
  final void Function(int index) onNavigate;
  const FamilyDashboardPage({super.key, required this.onNavigate});

  @override
  State<FamilyDashboardPage> createState() => _FamilyDashboardPageState();
}

class _FamilyDashboardPageState extends State<FamilyDashboardPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Dashboard'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder(
        future: api.getDashboard(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final msg = (data['msg'] ?? 'Welcome 👋').toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.home)),
                  title: Text(msg, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Use the tabs to manage elders, matching, monitoring and more.'),
                ),
              ),
              const SizedBox(height: 14),
              const SectionTitle('Quick actions'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ActionChip(avatar: const Icon(Icons.groups, size: 18), label: const Text('Elders'), onPressed: () => widget.onNavigate(1)),
                  ActionChip(avatar: const Icon(Icons.auto_awesome, size: 18), label: const Text('Match'), onPressed: () => widget.onNavigate(2)),
                  ActionChip(avatar: const Icon(Icons.warning_amber, size: 18), label: const Text('Alerts'), onPressed: () => widget.onNavigate(3)),
                  ActionChip(avatar: const Icon(Icons.calendar_month, size: 18), label: const Text('Calendar'), onPressed: () => widget.onNavigate(4)),
                  ActionChip(avatar: const Icon(Icons.call, size: 18), label: const Text('Calls'), onPressed: () => widget.onNavigate(5)),
                  ActionChip(avatar: const Icon(Icons.person, size: 18), label: const Text('Profile'), onPressed: () => widget.onNavigate(6)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

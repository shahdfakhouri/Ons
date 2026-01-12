import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class ElderContactsPage extends StatefulWidget {
  final int elderId;
  const ElderContactsPage({super.key, required this.elderId});

  @override
  State<ElderContactsPage> createState() => _ElderContactsPageState();
}

class _ElderContactsPageState extends State<ElderContactsPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    final elderId = widget.elderId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SectionTitle('Assigned caregiver'),
          FutureBuilder(
            future: api.getCaregiverContact(elderId),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No caregiver assigned.')));
              }
              final data = (snap.data as Map<String, dynamic>? ?? {});
              final c = (data['caregiver'] as Map?) ?? {};
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text((c['name'] ?? 'Caregiver').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('Phone: ${c['phone'] ?? '-'} • Email: ${c['email'] ?? '-'}'),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          const SectionTitle('Retirement home'),
          FutureBuilder(
            future: api.getHomeContact(elderId),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No retirement home linked.')));
              }
              final data = (snap.data as Map<String, dynamic>? ?? {});
              final h = (data['home'] as Map?) ?? {};
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.apartment),
                  title: Text((h['name'] ?? 'Home').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('Phone: ${h['contact_phone'] ?? '-'} • Email: ${h['contact_email'] ?? '-'} • City: ${h['city'] ?? '-'}'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

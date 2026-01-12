import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ons_app/services/elder_api.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> family = [];
  List<Map<String, dynamic>> caregiver = [];
  List<Map<String, dynamic>> home = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await api.contacts();
      family = (data['family'] as List? ?? []).cast<Map<String, dynamic>>();
      caregiver = (data['caregiver'] as List? ?? []).cast<Map<String, dynamic>>();
      home = (data['retirement_home'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() => loading = false);
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _email(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget section(String title, List<Map<String, dynamic>> list) {
    if (list.isEmpty) return Card(child: ListTile(title: Text(title), subtitle: const Text('No contacts')));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            ...list.map((c) {
              final name = c['name']?.toString() ?? title;
              final phone = (c['phone'] ?? c['contact_phone'])?.toString() ?? '';
              final email = (c['email'] ?? c['contact_email'])?.toString() ?? '';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text([if (phone.isNotEmpty) 'Phone: $phone', if (email.isNotEmpty) 'Email: $email'].join('\n')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (phone.isNotEmpty) IconButton(onPressed: () => _call(phone), icon: const Icon(Icons.call)),
                      if (email.isNotEmpty) IconButton(onPressed: () => _email(email), icon: const Icon(Icons.email)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          section('Family', family),
          const SizedBox(height: 10),
          section('Caregiver', caregiver),
          const SizedBox(height: 10),
          section('Retirement Home', home),
        ],
      ),
    );
  }
}

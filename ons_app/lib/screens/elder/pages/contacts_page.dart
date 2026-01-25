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
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Could not launch phone dialer');
    }
  }

  Future<void> _email(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Could not launch email app');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget section(String title, List<Map<String, dynamic>> list, bool isMobile) {
    if (list.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
        child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('No contacts found')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2, color: Color(0xFF8E9297))),
        ),
        ...list.map((c) {
          final name = c['name']?.toString() ?? title;
          final phone = (c['phone'] ?? c['contact_phone'])?.toString() ?? '';
          final email = (c['email'] ?? c['contact_email'])?.toString() ?? '';

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF313647).withOpacity(0.1),
                  child: const Icon(Icons.person, color: Color(0xFF313647)),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (phone.isNotEmpty) Text(phone, style: TextStyle(color: Colors.grey.shade600)),
                    if (email.isNotEmpty) Text(email, style: TextStyle(color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (phone.isNotEmpty) 
                      IconButton(
                        onPressed: () => _call(phone), 
                        icon: const Icon(Icons.call, color: Colors.green),
                        tooltip: 'Call',
                      ),
                    if (email.isNotEmpty) 
                      IconButton(
                        onPressed: () => _email(email), 
                        icon: const Icon(Icons.email, color: Color(0xFF435663)),
                        tooltip: 'Email',
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(body: Center(child: Text('Error: $error')));

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4), // Signature Ons Cream
      appBar: AppBar(
        title: const Text('Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        children: [
          section('Family', family, isMobile),
          section('Caregiver', caregiver, isMobile),
          section('Retirement Home', home, isMobile),
        ],
      ),
    );
  }
}
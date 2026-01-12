import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

import 'profile/payments_page.dart';
import 'profile/transactions_page.dart';
import 'profile/reviews_page.dart';
import 'profile/emergency_page.dart';
import 'profile/events_page.dart';

class FamilyProfilePage extends StatefulWidget {
  const FamilyProfilePage({super.key});

  @override
  State<FamilyProfilePage> createState() => _FamilyProfilePageState();
}

class _FamilyProfilePageState extends State<FamilyProfilePage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  final name = TextEditingController();
  final phone = TextEditingController();
  final city = TextEditingController();
  final budget = TextEditingController();
  final preference = TextEditingController(text: 'caregiver');
  final skills = TextEditingController();
  final hours = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    city.dispose();
    budget.dispose();
    preference.dispose();
    skills.dispose();
    hours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await api.updateProfile({
        'name': name.text.trim().isEmpty ? null : name.text.trim(),
        'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
        'city': city.text.trim().isEmpty ? null : city.text.trim(),
        'budget': double.tryParse(budget.text.trim()),
        'preference': preference.text.trim().isEmpty ? null : preference.text.trim(),
        'skills_required': skills.text.trim().isEmpty ? null : skills.text.trim(),
        'hours_needed': int.tryParse(hours.text.trim()),
      });
      if (!mounted) return;
      showSnack(context, 'Profile updated ✅');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder(
        future: api.getMyProfile(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final p = (data['profile'] as Map?) ?? {};

          // fill only if empty (avoid overwriting user typing on rebuild)
          if (name.text.isEmpty) name.text = (p['name'] ?? '').toString();
          if (phone.text.isEmpty) phone.text = (p['phone'] ?? '').toString();
          if (city.text.isEmpty) city.text = (p['city'] ?? '').toString();
          if (budget.text.isEmpty) budget.text = (p['budget'] ?? '').toString();
          if (preference.text.isEmpty) preference.text = (p['preference'] ?? 'caregiver').toString();
          if (skills.text.isEmpty) skills.text = (p['skills_required'] ?? '').toString();
          if (hours.text.isEmpty) hours.text = (p['hours_needed'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const SectionTitle('My Profile'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      AppTextField(controller: name, label: 'name'),
                      const SizedBox(height: 10),
                      AppTextField(controller: phone, label: 'phone'),
                      const SizedBox(height: 10),
                      AppTextField(controller: city, label: 'city'),
                      const SizedBox(height: 10),
                      AppTextField(controller: budget, label: 'budget', keyboardType: TextInputType.number),
                      const SizedBox(height: 10),
                      AppTextField(controller: preference, label: 'preference (caregiver/retirement_home)'),
                      const SizedBox(height: 10),
                      AppTextField(controller: skills, label: 'skills_required', maxLines: 2),
                      const SizedBox(height: 10),
                      AppTextField(controller: hours, label: 'hours_needed', keyboardType: TextInputType.number),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              const SectionTitle('More'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.payments),
                      title: const Text('Payments'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(const PaymentsPage()),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('Transactions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(const TransactionsPage()),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: const Text('Reviews'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(const ReviewsPage()),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sos),
                      title: const Text('Emergency'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(const EmergencyPage()),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Events (CRUD)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(const EventsPage()),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

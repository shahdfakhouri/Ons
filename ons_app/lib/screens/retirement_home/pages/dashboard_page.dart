import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementDashboardPage extends StatefulWidget {
  const RetirementDashboardPage({super.key});

  @override
  State<RetirementDashboardPage> createState() => _RetirementDashboardPageState();
}

class _RetirementDashboardPageState extends State<RetirementDashboardPage> {
  final _api = RetirementHomeApi();
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _homeInfo;
  Map<String, dynamic>? _stats;

  // profile form
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _services = TextEditingController();
  final _monthly = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _email.dispose();
    _phone.dispose();
    _services.dispose();
    _monthly.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final j = await _api.getDashboard();
      _homeInfo = (j['homeInfo'] as Map?)?.cast<String, dynamic>();
      _stats = (j['stats'] as Map?)?.cast<String, dynamic>();

      _name.text = (_homeInfo?['name'] ?? '').toString();
      _city.text = (_homeInfo?['city'] ?? '').toString();
      _email.text = (_homeInfo?['contact_email'] ?? '').toString();
      _phone.text = (_homeInfo?['contact_phone'] ?? '').toString();
      _services.text = (_homeInfo?['services'] ?? '').toString();
      _monthly.text = (_homeInfo?['monthly_cost'] ?? '').toString();

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _api.updateProfile({
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'contact_email': _email.text.trim(),
        'contact_phone': _phone.text.trim(),
        'services': _services.text.trim(),
        'monthly_cost': double.tryParse(_monthly.text.trim()) ?? _monthly.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated ✅')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final stats = _stats ?? {};
    final avg = (stats['avgHealth'] as Map?)?.cast<String, dynamic>() ?? {};

    Widget statTile(String title, dynamic value, IconData icon) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text('$value'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          statTile('Total Elders', stats['totalElders'] ?? '-', Icons.elderly),
          statTile('Total Caregivers', stats['totalCaregivers'] ?? '-', Icons.badge),
          statTile('Pending Payments', stats['pendingPayments'] ?? '-', Icons.payments),

          Card(
            child: ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: const Text('Average Health (latest logs)'),
              subtitle: Text(
                'Sugar: ${avg['avg_blood_sugar'] ?? '-'} | '
                'BP: ${avg['avg_blood_pressure'] ?? '-'} | '
                'Temp: ${avg['avg_temp'] ?? '-'}',
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text('Update Home Profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
                TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
                TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Contact Email')),
                TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Contact Phone')),
                TextFormField(controller: _services, decoration: const InputDecoration(labelText: 'Services')),
                TextFormField(controller: _monthly, decoration: const InputDecoration(labelText: 'Monthly Cost')),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

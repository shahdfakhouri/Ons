import 'package:flutter/material.dart';
import 'package:ons_app/services/caregiver_api.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _api = CaregiverApi();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _profile;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.getDashboard();
      final profile = await _api.getMyProfile();

      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEditProfile() async {
    final p = _profile ?? {};

    final phone = TextEditingController(text: (p['phone'] ?? '').toString());
    final city = TextEditingController(text: (p['city'] ?? '').toString());
    final skills = TextEditingController(text: (p['skills'] ?? '').toString());
    final expectedSalary = TextEditingController(text: (p['expected_salary'] ?? '').toString());
    final hoursPerDay = TextEditingController(text: (p['hours_per_day'] ?? '').toString());
    final status = TextEditingController(text: (p['status'] ?? '').toString());
    final lat = TextEditingController(text: (p['latitude'] ?? '').toString());
    final lng = TextEditingController(text: (p['longitude'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: skills, decoration: const InputDecoration(labelText: 'Skills'), maxLines: 2),
              TextField(
                controller: expectedSalary,
                decoration: const InputDecoration(labelText: 'Expected salary'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: hoursPerDay,
                decoration: const InputDecoration(labelText: 'Hours per day'),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: status, decoration: const InputDecoration(labelText: 'Status')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: lat,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lng,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    double? _tryDouble(String s) => s.trim().isEmpty ? null : double.tryParse(s.trim());
    int? _tryInt(String s) => s.trim().isEmpty ? null : int.tryParse(s.trim());

    final body = <String, dynamic>{
      'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
      'city': city.text.trim().isEmpty ? null : city.text.trim(),
      'skills': skills.text.trim().isEmpty ? null : skills.text.trim(),
      'expected_salary': _tryDouble(expectedSalary.text),
      'hours_per_day': _tryInt(hoursPerDay.text),
      'status': status.text.trim().isEmpty ? null : status.text.trim(),
      'latitude': _tryDouble(lat.text),
      'longitude': _tryDouble(lng.text),
    };

    try {
      await _api.updateProfile(body);
      _snack('Profile updated ✅');
      await _load();
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  void _goTab(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaregiverLayout(initialIndex: index)),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load dashboard', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final p = _profile ?? {};
    final name = (p['name'] ?? 'Caregiver').toString();
    final phone = (p['phone'] ?? '-').toString();
    final city = (p['city'] ?? '-').toString();
    final status = (p['status'] ?? '-').toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, $name', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text('Phone: $phone'),
                      Text('City: $city'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(status, style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _openEditProfile,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ActionChip(icon: Icons.people, label: 'Assigned Elders', onTap: () => _goTab(1)),
                    _ActionChip(icon: Icons.notifications, label: 'Alerts', onTap: () => _goTab(2)),
                    _ActionChip(icon: Icons.event, label: 'Upcoming Visits', onTap: () => _goTab(3)),
                    _ActionChip(icon: Icons.schedule, label: 'Shifts', onTap: () => _goTab(5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

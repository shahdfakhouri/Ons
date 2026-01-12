import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/models/elder_models.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/services/elder_auth_service.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final api = ElderApi();
  ElderProfile? profile;

  double _fontSize = 18;
  String _language = 'ar';
  bool _voiceMode = false;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await api.getMe();
      final p = ElderProfile.fromJson(data);
      setState(() {
        profile = p;
        _fontSize = p.fontSize ?? 18;
        _language = p.language ?? 'ar';
        _voiceMode = p.voiceMode ?? false;
        loading = false;
      });
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() { loading = true; error = null; });
    try {
      await api.updateMe(fontSize: _fontSize, language: _language, voiceMode: _voiceMode);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved ✅')));
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _changePin() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );

    if (ok != true) return;
    final newPin = ctrl.text.trim();
    if (newPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be at least 4 digits')));
      return;
    }

    try {
      await api.changePin(newPin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _logout() async {
    await ElderAuthService().logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Accessibility'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'My Profile',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${profile?.name ?? "-"}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Age: ${profile?.age ?? "-"}'),
                Text('Gender: ${profile?.gender ?? "-"}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: 'Accessibility',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Font size: ${_fontSize.toStringAsFixed(0)}'),
                Slider(
                  min: 14,
                  max: 28,
                  divisions: 14,
                  value: _fontSize,
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) => setState(() => _language = v ?? 'ar'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Voice mode'),
                  subtitle: const Text('Bigger text + voice-first UI'),
                  value: _voiceMode,
                  onChanged: (v) => setState(() => _voiceMode = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: 'Security',
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.lock),
                    label: const Text('Change PIN'),
                    onPressed: _changePin,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    onPressed: _logout,
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

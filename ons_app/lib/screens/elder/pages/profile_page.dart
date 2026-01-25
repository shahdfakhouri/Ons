import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/models/elder_models.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/services/elder_auth_service.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class ProfilePage extends StatefulWidget {
  // ✅ 1. Accept the onBack navigation callback
  final void Function(int index)? onBack;
  const ProfilePage({super.key, this.onBack});

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

  // Colors aligned with your ONS palette
  static const _deepNavy = Color(0xFF313647);
  static const _cream = Color(0xFFF9F9F4);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ 2. Helper to return to Index 0 (Home)
  void _triggerBack() {
    if (widget.onBack != null) {
      widget.onBack!(0);
    }
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await api.getMe();
      final p = ElderProfile.fromJson(data);
      if (mounted) {
        setState(() {
          profile = p;
          _fontSize = p.fontSize ?? 18;
          _language = p.language ?? 'ar';
          _voiceMode = p.voiceMode ?? false;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() { loading = true; error = null; });
    try {
      await api.updateMe(fontSize: _fontSize, language: _language, voiceMode: _voiceMode);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Saved ✅'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _changePin() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Security PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New 4-Digit PIN', border: OutlineInputBorder()),
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
    // Clear stack and return to Login
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: _deepNavy)));
    if (error != null) return Scaffold(body: Center(child: Text('Error: $error')));

    // ✅ 3. PopScope intercepts the device back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          // ✅ 4. Manual back button navigation
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _deepNavy),
            onPressed: _triggerBack,
          ),
          title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold, color: _deepNavy)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: _deepNavy)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Personal Info',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                title: Text(profile?.name ?? "Resident", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                subtitle: Text('Age: ${profile?.age ?? "-"} • ${profile?.gender ?? "-"}'),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Accessibility',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Text Size: ${_fontSize.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    min: 14,
                    max: 32, // Increased max for better elder accessibility
                    divisions: 9,
                    activeColor: _deepNavy,
                    value: _fontSize,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _language,
                    decoration: const InputDecoration(labelText: 'App Language', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية (Arabic)')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (v) => setState(() => _language = v ?? 'ar'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Voice Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Enables voice commands and audio feedback'),
                    value: _voiceMode,
                    activeColor: _deepNavy,
                    onChanged: (v) => setState(() => _voiceMode = v),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(backgroundColor: _deepNavy),
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Privacy & Security',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline, color: _deepNavy),
                    title: const Text('Security PIN'),
                    subtitle: const Text('Update your 4-digit access code'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePin,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
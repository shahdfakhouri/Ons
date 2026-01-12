import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class ElderConsentPinPage extends StatefulWidget {
  final int elderId;
  const ElderConsentPinPage({super.key, required this.elderId});

  @override
  State<ElderConsentPinPage> createState() => _ElderConsentPinPageState();
}

class _ElderConsentPinPageState extends State<ElderConsentPinPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  final pin = TextEditingController();

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> _resetPin() async {
    try {
      await api.resetElderPin(widget.elderId, pin.text.trim());
      if (!mounted) return;
      showSnack(context, 'PIN reset ✅');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _toggleConsent() async {
    try {
      await api.setElderConsent(widget.elderId); // toggle
      if (!mounted) return;
      showSnack(context, 'Consent toggled ✅');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elderId = widget.elderId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consent & PIN'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Visibility consent'),
              subtitle: const Text('Monitoring endpoints depend on elder consent.'),
              trailing: ElevatedButton(onPressed: _toggleConsent, child: const Text('Toggle')),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text('Reset PIN (Elder ID: $elderId)', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  AppTextField(controller: pin, label: 'New PIN (min 4 digits)', keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _resetPin, child: const Text('Reset PIN'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

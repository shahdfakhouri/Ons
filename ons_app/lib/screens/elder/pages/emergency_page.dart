import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/emergency_history_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/big_button.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final api = ElderApi();
  bool loading = false;

  Future<void> _panic() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emergency'),
        content: const Text('Are you sure you want to send an emergency alert?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => loading = true);
    try {
      await api.panic();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency sent ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyHistoryPage())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          BigButton(
            icon: Icons.sos,
            title: loading ? 'Sending...' : 'Panic Button',
            subtitle: 'Tap only if you need urgent help',
            danger: true,
            onTap: loading ? null : _panic,
          ),
          const SizedBox(height: 10),
          const SectionCard(
            title: 'Tip',
            child: Text('If you feel dizzy, chest pain, or can’t breathe — press Panic immediately.'),
          ),
        ],
      ),
    );
  }
}

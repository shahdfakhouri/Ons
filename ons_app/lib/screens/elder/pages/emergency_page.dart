import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/emergency_history_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/big_button.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class EmergencyPage extends StatefulWidget {
  // ✅ 1. Accept the navigation callback for Index syncing
  final void Function(int index)? onBack;
  const EmergencyPage({super.key, this.onBack});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final api = ElderApi();
  bool loading = false;

  // Colors aligned with your ONS palette
  static const _deepNavy = Color(0xFF313647);
  static const _cream = Color(0xFFF9F9F4);

  Future<void> _panic() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Emergency', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Do you need immediate help? We will notify your family and caregivers right now.'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel', style: TextStyle(color: _deepNavy, fontWeight: FontWeight.bold))
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true), 
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('YES, SEND ALERT'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => loading = true);
    try {
      await api.panic();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency alert sent to staff and family! ✅'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        )
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        // ✅ 2. Prevent exiting to website homepage
        automaticallyImplyLeading: false,
        title: const Text('Emergency Assistance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ✅ 3. Manual back button to return to Elder Home (Index 0)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _deepNavy),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!(0);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: _deepNavy),
            tooltip: 'Alert History',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyHistoryPage())),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        children: [
          const SizedBox(height: 20),
          BigButton(
            icon: Icons.sos,
            title: loading ? 'SENDING ALERT...' : 'TAP FOR HELP',
            subtitle: 'This will alert everyone assigned to your care.',
            danger: true,
            onTap: loading ? null : _panic,
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Safety Tip',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'If you feel dizzy, have chest pain, or had a fall, press the red button immediately.',
                      style: TextStyle(fontSize: isMobile ? 14 : 16, color: const Color(0xFF435663), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Additional quick action for non-critical help
          OutlinedButton.icon(
            onPressed: () {
              if (widget.onBack != null) widget.onBack!(5); // Link to Calls Page (Index 5)
            },
            icon: const Icon(Icons.phone_in_talk, size: 20),
            label: const Text('Not an emergency? Call someone instead'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: _deepNavy),
              foregroundColor: _deepNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
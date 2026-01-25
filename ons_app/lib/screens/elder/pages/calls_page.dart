import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/contacts_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class CallsPage extends StatefulWidget {
  // ✅ 1. Accept the navigation callback
  final void Function(int index)? onBack;
  const CallsPage({super.key, this.onBack});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  final api = ElderApi();

  bool loading = true;
  String? error;
  List<dynamic> items = [];

  final targetIdCtrl = TextEditingController();
  String targetRole = 'family';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    targetIdCtrl.dispose(); // ✅ Best practice to dispose controllers
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      items = await api.callHistory();
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _requestCall() async {
    final id = int.tryParse(targetIdCtrl.text.trim());
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid target user id')));
      return;
    }

    try {
      await api.requestCall(targetUserId: id, targetRole: targetRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call request sent ✅')));
      targetIdCtrl.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _acceptDecline(dynamic e, bool accept) async {
    final callId = e['call_id'] ?? e['id'];
    if (callId == null) return;

    try {
      if (accept) {
        await api.acceptCall(int.parse('$callId'));
      } else {
        await api.declineCall(int.parse('$callId'));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accept ? 'Accepted ✅' : 'Declined ✅')));
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        // ✅ 2. Disable default back button to prevent going to website landing page
        automaticallyImplyLeading: false,
        title: const Text('Calls'),
        // ✅ 3. Custom leading button to go to Elder Home (Index 0)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!(0);
            }
          },
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsPage())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Request a call',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: targetRole,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Target role'),
                  items: const [
                    DropdownMenuItem(value: 'family', child: Text('Family')),
                    DropdownMenuItem(value: 'caregiver', child: Text('Caregiver')),
                    DropdownMenuItem(value: 'retirement_home', child: Text('Retirement Home')),
                  ],
                  onChanged: (v) => setState(() => targetRole = v ?? 'family'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: targetIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Target user id',
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text('Send request'),
                    onPressed: _requestCall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: 'Call History',
            child: items.isEmpty
                ? const Text('No calls yet')
                : Column(
                    children: items.map((e) {
                      final m = e as Map;
                      final role = m['target_role']?.toString() ?? '';
                      final status = m['status']?.toString() ?? '';
                      final at = m['created_at']?.toString() ?? '';
                      final pending = status.toLowerCase() == 'pending';

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.call),
                          title: Text('To: $role', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text([if (status.isNotEmpty) 'Status: $status', if (at.isNotEmpty) at].join(' • ')),
                          trailing: pending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(onPressed: () => _acceptDecline(m, true), icon: const Icon(Icons.check, color: Colors.green)),
                                    IconButton(onPressed: () => _acceptDecline(m, false), icon: const Icon(Icons.close, color: Colors.red)),
                                  ],
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
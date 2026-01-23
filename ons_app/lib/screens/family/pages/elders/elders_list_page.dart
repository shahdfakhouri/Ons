// ======================
// FAMILY: EldersListPage (optional Chat entry per elder)
// If you want: a Chat button that starts chat with the assigned caregiver.
// ======================
import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';
import 'elder_hub_page.dart';

import 'package:ons_app/services/chat_h2h_api.dart';
import 'package:ons_app/screens/chat_h2h/chat_page.dart';

class EldersListPage extends StatefulWidget {
  const EldersListPage({super.key});

  @override
  State<EldersListPage> createState() => _EldersListPageState();
}

class _EldersListPageState extends State<EldersListPage> {
  final api = FamilyApi();
  final chatApi = ChatH2HApi();

  bool _chatBusy = false;

  Future<void> _reload() async => setState(() {});

  Future<void> _openChatForElder(Map e) async {
    if (_chatBusy) return;

    final elderId = int.tryParse((e['elder_id'] ?? '').toString());
    if (elderId == null) return;

    // This requires backend to return the assigned caregiver_id in listMyElders()
    // OR you call your endpoint getCaregiverContact(elderId) to fetch caregiver_id.
    final caregiverId = int.tryParse((e['caregiver_id'] ?? '').toString());
    if (caregiverId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing caregiver_id. Add it to /family/elders or fetch from caregiver-contact.')),
      );
      return;
    }

    // FamilyId can be taken from JWT on backend, but your create body expects it.
    // Best: modify backend to use req.user.id as familyId.
    // For now, if you already return family_id from listMyElders, use it:
    final familyId = int.tryParse((e['family_id'] ?? '').toString());
    if (familyId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing family_id. Add it or update backend to use req.user.id.')),
      );
      return;
    }

    setState(() => _chatBusy = true);

    try {
      final res = await chatApi.createOrGetConversation(
        elderId: elderId,
        caregiverId: caregiverId,
        familyId: familyId,
      );
      final convId = (res['conversationId'] ?? '').toString();
      if (convId.isEmpty) throw Exception('No conversationId returned');

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatH2HPage(conversationId: convId)),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat failed: $err')),
      );
    } finally {
      if (mounted) setState(() => _chatBusy = false);
    }
  }

  Future<void> _openCreateDialog() async {
    final name = TextEditingController();
    final dob = TextEditingController();
    final gender = TextEditingController();
    final age = TextEditingController();
    final relation = TextEditingController(text: 'family');
    bool isPrimary = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Elder'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              AppTextField(controller: name, label: 'Name'),
              const SizedBox(height: 10),
              AppTextField(controller: dob, label: 'DOB (YYYY-MM-DD) optional'),
              const SizedBox(height: 10),
              AppTextField(controller: gender, label: 'Gender optional'),
              const SizedBox(height: 10),
              AppTextField(controller: age, label: 'Age optional', keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              AppTextField(controller: relation, label: 'Relation (optional)'),
              const SizedBox(height: 8),
              SwitchListTile(
                value: isPrimary,
                onChanged: (v) => isPrimary = v,
                title: const Text('Primary elder'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await api.createElder({
        'name': name.text.trim(),
        'dob': dob.text.trim().isEmpty ? null : dob.text.trim(),
        'gender': gender.text.trim().isEmpty ? null : gender.text.trim(),
        'age': int.tryParse(age.text.trim()),
        'relation': relation.text.trim().isEmpty ? null : relation.text.trim(),
        'is_primary': isPrimary,
      });
      if (!mounted) return;
      showSnack(context, 'Elder created ✅');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Elders'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: api.listMyElders(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final elders = (data['elders'] as List?) ?? const [];

          if (elders.isEmpty) {
            return const EmptyState(
              title: 'No elders yet',
              subtitle: 'Press + to create the first elder.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: elders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = elders[i] as Map;
              final id = (e['elder_id'] ?? '').toString();
              final name = (e['name'] ?? 'Elder').toString();
              final rel = (e['relation'] ?? '').toString();
              final age = (e['age'] ?? '').toString();
              final homeId = (e['home_id'] ?? '').toString();

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('ID: $id   •   Relation: $rel   •   Age: $age   •   Home: $homeId'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Chat with caregiver',
                        onPressed: _chatBusy ? null : () => _openChatForElder(e),
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ElderHubPage(elderId: int.parse(id), elderName: name)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

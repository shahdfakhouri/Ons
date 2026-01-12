import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  final elderId = TextEditingController();
  String targetRole = 'elder'; // elder/caregiver/retirement_home
  String callType = 'voice';   // voice/video
  final notes = TextEditingController();

  final filterElder = TextEditingController();
  final from = TextEditingController();
  final to = TextEditingController();

  @override
  void dispose() {
    elderId.dispose();
    notes.dispose();
    filterElder.dispose();
    from.dispose();
    to.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final eId = int.tryParse(elderId.text.trim());
    if (eId == null) {
      showSnack(context, 'elder_id required', isError: true);
      return;
    }

    try {
      await api.requestCall({
        'elder_id': eId,
        'target_role': targetRole,
        'type': callType,
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, 'Call request created ✅');
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
        title: const Text('Calls'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SectionTitle('Request a call'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  AppTextField(controller: elderId, label: 'elder_id', keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: targetRole,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'target_role'),
                    items: const [
                      DropdownMenuItem(value: 'elder', child: Text('elder')),
                      DropdownMenuItem(value: 'caregiver', child: Text('caregiver')),
                      DropdownMenuItem(value: 'retirement_home', child: Text('retirement_home')),
                    ],
                    onChanged: (v) => setState(() => targetRole = v ?? 'elder'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: callType,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'type'),
                    items: const [
                      DropdownMenuItem(value: 'voice', child: Text('voice')),
                      DropdownMenuItem(value: 'video', child: Text('video')),
                    ],
                    onChanged: (v) => setState(() => callType = v ?? 'voice'),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(controller: notes, label: 'notes (optional)', maxLines: 2),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _request, child: const Text('Request'))),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const SectionTitle('History filters (optional)'),
          Row(
            children: [
              Expanded(child: AppTextField(controller: filterElder, label: 'elder_id')),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: from, label: 'from (YYYY-MM-DD)')),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: to, label: 'to (YYYY-MM-DD)')),
            ],
          ),
          const SizedBox(height: 10),

          FutureBuilder(
            future: api.getCallHistory(
              elderId: filterElder.text.trim().isEmpty ? null : filterElder.text.trim(),
              from: (from.text.trim().isEmpty || to.text.trim().isEmpty) ? null : from.text.trim(),
              to: (from.text.trim().isEmpty || to.text.trim().isEmpty) ? null : to.text.trim(),
            ),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final calls = (data['calls'] as List?) ?? const [];

              if (calls.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No calls yet.')));

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: calls.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = calls[i] as Map;
                    return ListTile(
                      leading: const Icon(Icons.call),
                      title: Text('To: ${c['receiver_role']}  #${c['receiver_id']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Elder: ${c['elder_id']} • Type: ${c['call_type']} • Status: ${c['status']} • ${c['created_at'] ?? ''}'),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

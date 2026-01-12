import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  final elderId = TextEditingController();
  final type = TextEditingController(text: 'panic');
  final severity = TextEditingController(text: 'high');
  final desc = TextEditingController();

  final filterElder = TextEditingController();
  final status = TextEditingController();
  final from = TextEditingController();
  final to = TextEditingController();

  @override
  void dispose() {
    elderId.dispose();
    type.dispose();
    severity.dispose();
    desc.dispose();
    filterElder.dispose();
    status.dispose();
    from.dispose();
    to.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final eId = int.tryParse(elderId.text.trim());
    if (eId == null) {
      showSnack(context, 'elder_id is required', isError: true);
      return;
    }
    try {
      await api.createEmergencyRequest({
        'elder_id': eId,
        'emergency_type': type.text.trim(),
        'severity': severity.text.trim(),
        'description': desc.text.trim().isEmpty ? null : desc.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, 'Emergency created 🚨');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await api.cancelEmergencyRequest(id);
      if (!mounted) return;
      showSnack(context, 'Cancelled ✅');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency'), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))]),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SectionTitle('Create emergency'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  AppTextField(controller: elderId, label: 'elder_id', keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  AppTextField(controller: type, label: 'emergency_type'),
                  const SizedBox(height: 10),
                  AppTextField(controller: severity, label: 'severity (low/medium/high/critical)'),
                  const SizedBox(height: 10),
                  AppTextField(controller: desc, label: 'description (optional)', maxLines: 3),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _create, child: const Text('Create'))),
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
              Expanded(child: AppTextField(controller: status, label: 'status')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: AppTextField(controller: from, label: 'from (YYYY-MM-DD)')),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: to, label: 'to (YYYY-MM-DD)')),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _reload, child: const Text('Load')),
            ],
          ),
          const SizedBox(height: 10),

          FutureBuilder(
            future: api.getEmergencyHistory(
              elderId: filterElder.text.trim().isEmpty ? null : filterElder.text.trim(),
              status: status.text.trim().isEmpty ? null : status.text.trim(),
              from: (from.text.trim().isEmpty || to.text.trim().isEmpty) ? null : from.text.trim(),
              to: (from.text.trim().isEmpty || to.text.trim().isEmpty) ? null : to.text.trim(),
            ),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final list = (data['emergencies'] as List?) ?? const [];

              if (list.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No emergencies.')));

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = list[i] as Map;
                    final id = int.tryParse(e['emergency_id']?.toString() ?? '') ?? 0;
                    final st = (e['status'] ?? '').toString();

                    return ListTile(
                      leading: const Icon(Icons.sos),
                      title: Text('Elder: ${e['elder_id']} • ${e['emergency_type']} • ${e['severity']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Status: $st • ${e['created_at'] ?? ''}\n${e['description'] ?? ''}'),
                      trailing: st == 'open'
                          ? TextButton(onPressed: () => _cancel(id), child: const Text('Cancel'))
                          : null,
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

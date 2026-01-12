import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  final api = FamilyApi();

  Future<void> _reload() async => setState(() {});
  bool _running = false;

  List<Map<String, dynamic>> _results = [];

  Future<void> _runMatch() async {
    setState(() => _running = true);
    try {
      final res = await api.runMatch();
      final matches = (res['matches'] as List?) ?? const [];
      setState(() => _results = matches.cast<Map<String, dynamic>>());
      if (!mounted) return;
      showSnack(context, 'Match results loaded ✅');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    } finally {
      setState(() => _running = false);
    }
  }

  Future<void> _assignDialog(Map<String, dynamic> m) async {
    final elderId = TextEditingController();
    final id = int.tryParse(m['id']?.toString() ?? '') ?? 0;
    final roleGuess = (m.containsKey('monthly_cost') ? 'retirement_home' : 'caregiver');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(roleGuess == 'caregiver' ? 'Assign caregiver' : 'Select home'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: elderId, label: 'elder_id', keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            Text('Selected ID: $id'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (ok != true) return;
    final eId = int.tryParse(elderId.text.trim());
    if (eId == null) return;

    try {
      if (roleGuess == 'caregiver') {
        await api.assignCaregiver(elderId: eId, caregiverId: id);
        if (!mounted) return;
        showSnack(context, 'Caregiver assigned ✅');
      } else {
        await api.selectHome(elderId: eId, homeId: id);
        if (!mounted) return;
        showSnack(context, 'Home selected ✅');
      }
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
        title: const Text('Match'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Run matching'),
              subtitle: const Text('Uses your profile (city/budget/preference).'),
              trailing: ElevatedButton(
                onPressed: _running ? null : _runMatch,
                child: Text(_running ? 'Running...' : 'Run'),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const SectionTitle('Latest results'),
          if (_results.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Run match to see results.')))
          else
            ..._results.map((m) {
              final name = (m['name'] ?? 'Match').toString();
              final city = (m['city'] ?? '').toString();
              final score = (m['score'] ?? '').toString();
              final isCaregiver = !m.containsKey('monthly_cost');

              return Card(
                child: ListTile(
                  leading: Icon(isCaregiver ? Icons.person : Icons.apartment),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('City: $city • Score: $score'),
                  trailing: ElevatedButton(
                    onPressed: () => _assignDialog(m),
                    child: Text(isCaregiver ? 'Assign' : 'Select'),
                  ),
                ),
              );
            }),

          const SizedBox(height: 12),
          const SectionTitle('Match history'),
          FutureBuilder(
            future: api.getMatches(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) {
                return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));
              }

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final list = (data['matches'] as List?) ?? const [];

              if (list.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No history yet.')));
              }

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = list[i] as Map;
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text('Matched: ${r['matched_role']}  #${r['matched_id']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Score: ${r['score']} • ${r['created_at'] ?? ''}'),
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

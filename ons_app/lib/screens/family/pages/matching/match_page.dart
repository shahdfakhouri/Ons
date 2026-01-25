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

  // 🎨 Signature Theme Palette
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

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
      showSnack(context, 'New recommendations found ✅');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    } finally {
      setState(() => _running = false);
    }
  }

  // ✅ UPDATED: Dialog now prioritizes Names over IDs
  Future<void> _assignDialog(Map<String, dynamic> m) async {
    final elderIdController = TextEditingController();
    final providerName = m['name'] ?? 'This Provider';
    final providerId = int.tryParse(m['id']?.toString() ?? '') ?? 0;
    final isCaregiver = !m.containsKey('monthly_cost');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(isCaregiver ? 'Assign Caregiver' : 'Select Facility', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Confirm assignment for:", style: TextStyle(color: _denim, fontSize: 13)),
            const SizedBox(height: 4),
            Text(providerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _deepNavy)),
            const SizedBox(height: 20),
            AppTextField(controller: elderIdController, label: 'Enter Elder ID', keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true), 
            style: FilledButton.styleFrom(backgroundColor: _deepNavy), 
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final eId = int.tryParse(elderIdController.text.trim());
    if (eId == null) return;

    try {
      if (isCaregiver) {
        await api.assignCaregiver(elderId: eId, caregiverId: providerId);
        showSnack(context, 'Assigned $providerName ✅');
      } else {
        await api.selectHome(elderId: eId, homeId: providerId);
        showSnack(context, 'Selected $providerName ✅');
      }
      _reload();
    } catch (e) {
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Care Matching', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _deepNavy,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildActionHeader(),
          const SizedBox(height: 32),
          const SectionTitle('Smart Recommendations'),
          const SizedBox(height: 16),
          if (_results.isEmpty)
            _buildEmptyState()
          else
            ..._results.map((m) => _buildMatchCard(m)),
          
          const SizedBox(height: 32),
          const SectionTitle('Recent Match Logs'),
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildActionHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _deepNavy,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI Search Engine", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text("Finding providers that fit your budget, location, and care needs.", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _running ? null : _runMatch,
              style: FilledButton.styleFrom(backgroundColor: _sage, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: _running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome),
              label: Text(_running ? "Searching..." : "Start Intelligent Match", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> m) {
    final name = m['name'] ?? 'Provider';
    final city = m['city'] ?? 'Location N/A';
    final score = double.tryParse(m['score']?.toString() ?? '0') ?? 0.0;
    final isCaregiver = !m.containsKey('monthly_cost');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _sage.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(isCaregiver ? Icons.person_rounded : Icons.apartment_rounded, color: _sage, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: _deepNavy, fontSize: 16)),
                  Text(city, style: const TextStyle(color: _denim, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${score.toInt()}% Match", style: const TextStyle(fontWeight: FontWeight.w900, color: _sage, fontSize: 14)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _assignDialog(m),
                  style: TextButton.styleFrom(
                    backgroundColor: _deepNavy.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isCaregiver ? 'Assign' : 'Select', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _deepNavy)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return FutureBuilder(
      future: api.getMatches(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator(color: _sage);
        final list = (snap.data as Map?)?['matches'] as List? ?? [];
        if (list.isEmpty) return const Text("No previous matching records.");

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            children: list.take(3).map((r) {
              final type = r['matched_role'].toString().replaceAll('_', ' ');
              return ListTile(
                leading: const Icon(Icons.history_rounded, size: 20, color: _denim),
                title: Text('$type #${r['matched_id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Accuracy Score: ${r['score']}%', style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 16),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: const Center(
        child: Text(
          "Trigger the AI search above to find care providers tailored to your budget and region.", 
          textAlign: TextAlign.center, 
          style: TextStyle(color: _denim, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
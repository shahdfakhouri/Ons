import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'elder_details_page.dart';

class RetirementEldersPage extends StatefulWidget {
  const RetirementEldersPage({super.key});

  @override
  State<RetirementEldersPage> createState() => _RetirementEldersPageState();
}

class _RetirementEldersPageState extends State<RetirementEldersPage> {
  final _api = RetirementHomeApi();

  // 🎨 Signature Theme Palette
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _elders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.getEldersMonitoring();
      setState(() { _elders = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _deepNavy));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    final assigned = _elders.where((e) => e['caregiver_name'] != null).toList();
    final waiting = _elders.where((e) => e['caregiver_name'] == null).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: _deepNavy,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          _buildHeader("Resident Monitoring", "Real-time oversight of all facility residents"),
          const SizedBox(height: 32),
          _buildSectionHeader("Active Monitoring", assigned.length, _sage),
          ...assigned.map((e) => _buildElderCard(e, isWaiting: false)),
          const SizedBox(height: 48),
          _buildSectionHeader("Awaiting Caregiver", waiting.length, _denim),
          if (waiting.isEmpty) _buildEmptyState("All residents are currently paired.")
          else ...waiting.map((e) => _buildElderCard(e, isWaiting: true)),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _deepNavy, letterSpacing: -1)),
        Text(subtitle, style: const TextStyle(color: _denim, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _deepNavy)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildElderCard(Map<String, dynamic> e, {required bool isWaiting}) {
    final id = (e['elder_id'] ?? 0) as num;
    final name = (e['elder_name'] ?? e['name'] ?? 'Resident').toString();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => RetirementElderDetailsPage(elderId: id.toInt())));
          _load();
        },
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: _cream,
          child: Text(name[0], style: const TextStyle(color: _deepNavy, fontWeight: FontWeight.w900, fontSize: 18)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _deepNavy)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _dataChip(Icons.badge_outlined, e['caregiver_name'] ?? 'Unassigned', isWaiting ? Colors.orange : _sage),
              const SizedBox(width: 8),
              _dataChip(Icons.cake_outlined, "${e['age'] ?? '??'} yrs", _denim),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: _denim),
      ),
    );
  }

  Widget _dataChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Center(child: Text(msg, style: const TextStyle(color: _denim, fontStyle: FontStyle.italic))),
    );
  }
}
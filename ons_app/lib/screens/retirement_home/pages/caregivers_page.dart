import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementCaregiversPage extends StatefulWidget {
  const RetirementCaregiversPage({super.key});
  @override
  State<RetirementCaregiversPage> createState() => _RetirementCaregiversPageState();
}

class _RetirementCaregiversPageState extends State<RetirementCaregiversPage> {
  final _api = RetirementHomeApi();
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);
  
  bool _loading = true;
  List<Map<String, dynamic>> _staff = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getHomeCaregivers();
      setState(() { _staff = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _deepNavy));

    final occupied = _staff.where((c) => (c['assignment_count'] ?? 0) > 0).toList();
    final available = _staff.where((c) => (c['assignment_count'] ?? 0) == 0).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: _deepNavy,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          _buildHeader("Active Assignments", occupied.length, _denim),
          if (occupied.isEmpty) _buildEmpty("No staff currently assigned to residents.")
          else ...occupied.map((c) => _buildStaffTile(c, isBusy: true)),

          const SizedBox(height: 48),

          _buildHeader("Available for Assignment", available.length, _sage),
          if (available.isEmpty) _buildEmpty("All staff members are currently occupied.")
          else ...available.map((c) => _buildStaffTile(c, isBusy: false)),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _deepNavy)),
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

  Widget _buildEmpty(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Text(msg, style: const TextStyle(color: _denim, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildStaffTile(Map<String, dynamic> c, {required bool isBusy}) {
    final accent = isBusy ? _denim : _sage;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            height: 52, width: 52,
            decoration: BoxDecoration(color: _cream.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(c['name'][0], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _deepNavy))),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _deepNavy)),
                Text(c['phone'] ?? c['email'], style: const TextStyle(color: _denim, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Text(isBusy ? "OCCUPIED" : "AVAILABLE", style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'package:intl/intl.dart';

class RetirementShiftsPage extends StatefulWidget {
  const RetirementShiftsPage({super.key});

  @override
  State<RetirementShiftsPage> createState() => _RetirementShiftsPageState();
}

class _RetirementShiftsPageState extends State<RetirementShiftsPage> {
  final _api = RetirementHomeApi();

  // 🎨 Your Signature Theme Palette
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _activeShifts = [];
  List<Map<String, dynamic>> _allStaff = [];

  int? _selectedStaffId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getActiveShifts(),
        _api.getHomeCaregivers(), // Fetch roster for selection
      ]);
      setState(() {
        _activeShifts = results[0];
        _allStaff = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _handleShift(bool isStarting) async {
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a staff member')));
      return;
    }

    final notes = await _askNotes();
    try {
      if (isStarting) {
        await _api.startShift(_selectedStaffId!, notes: notes);
      } else {
        await _api.endShift(_selectedStaffId!, notes: notes);
      }
      _selectedStaffId = null;
      await _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isStarting ? 'Shift started ✅' : 'Shift ended ✅'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<String?> _askNotes() async {
    final c = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Shift Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Enter hand-over notes...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Skip')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), style: FilledButton.styleFrom(backgroundColor: _deepNavy), child: const Text('Save')),
        ],
      ),
    );
    c.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _deepNavy));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _deepNavy,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          _buildHeader("Staff Attendance", "Manage clock-ins and active shifts"),
          const SizedBox(height: 24),
          _buildControlPanel(),
          const SizedBox(height: 48),
          _buildSectionTitle("Currently On Duty", _activeShifts.length),
          if (_activeShifts.isEmpty) 
            _buildEmptyState("No staff members are currently clocked in.")
          else 
            ..._activeShifts.map((s) => _buildShiftCard(s)),
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

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 40)],
      ),
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: _selectedStaffId,
            decoration: _inputDecoration("Select Staff Member", Icons.badge_rounded),
            dropdownColor: Colors.white,
            items: _allStaff.map<DropdownMenuItem<int>>((s) {
              return DropdownMenuItem<int>(
                value: (s['caregiver_id'] as num).toInt(),
                child: Text(s['name'] ?? 'Staff'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedStaffId = val),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _actionBtn("Stop Shift", Icons.stop_rounded, Colors.redAccent, () => _handleShift(false))),
              const SizedBox(width: 16),
              Expanded(child: _actionBtn("Start Shift", Icons.play_arrow_rounded, _sage, () => _handleShift(true))),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 60,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> s) {
    final name = s['caregiver_name'] ?? 'Staff';
    final start = s['shift_start'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: _cream,
            child: Text(name[0], style: const TextStyle(color: _deepNavy, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _deepNavy)),
                Text("Clocked in: $start", style: const TextStyle(color: _denim, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openHistory((s['caregiver_id'] as num).toInt()),
            icon: const Icon(Icons.history_rounded, color: _sage),
          ),
        ],
      ),
    );
  }

  // Preservation of your history logic with styling
  Future<void> _openHistory(int id) async {
    try {
      final list = await _api.getCaregiverShiftHistory(id, limit: 30);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: _cream,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        builder: (_) => ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final h = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Session: ${h['shift_start']}", style: const TextStyle(fontWeight: FontWeight.bold, color: _deepNavy)),
                  Text("Ended: ${h['shift_end'] ?? 'In Progress'}", style: const TextStyle(color: _denim, fontSize: 13)),
                  if (h['notes'] != null) Text("Note: ${h['notes']}", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _denim, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: _deepNavy, size: 22),
      filled: true,
      fillColor: _cream.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _deepNavy)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: _sage.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('$count', style: const TextStyle(color: _deepNavy, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Center(child: Text(msg, style: const TextStyle(color: _denim, fontStyle: FontStyle.italic))),
    );
  }
}
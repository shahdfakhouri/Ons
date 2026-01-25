import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementAssignmentsPage extends StatefulWidget {
  const RetirementAssignmentsPage({super.key});

  @override
  State<RetirementAssignmentsPage> createState() => _RetirementAssignmentsPageState();
}

class _RetirementAssignmentsPageState extends State<RetirementAssignmentsPage> {
  final _api = RetirementHomeApi();
  
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _availableElders = [];
  List<Map<String, dynamic>> _availableStaff = [];

  int? _selectedElderId;
  int? _selectedStaffId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getAssignments(),
        _api.getEldersMonitoring(), 
        _api.getHomeCaregivers(),
      ]);

      setState(() {
        _assignments = results[0];
        _availableElders = (results[1] as List)
            .where((e) => e['caregiver_id'] == null)
            .cast<Map<String, dynamic>>()
            .toList();
        _availableStaff = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _assign() async {
    if (_selectedElderId == null || _selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a resident and a staff member'))
      );
      return;
    }

    try {
      await _api.assignCaregiverToElder(
        elderId: _selectedElderId!, 
        caregiverId: _selectedStaffId!
      );
      _selectedElderId = null;
      _selectedStaffId = null;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relationship Created ✅'), behavior: SnackBarBehavior.floating)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _remove(int eId, int sId) async {
    try {
      await _api.removeAssignment(elderId: eId, caregiverId: sId);
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment Dissolved ❎'), behavior: SnackBarBehavior.floating)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _deepNavy));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return RefreshIndicator(
      onRefresh: _load,
      color: _deepNavy,
      child: ListView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        children: [
          _buildHeader("Pairing System", "Link residents with their dedicated caregivers", isMobile),
          const SizedBox(height: 24),
          _buildSelectionTool(isMobile),
          const SizedBox(height: 40),
          _buildHeader("Active Pairings", "${_assignments.length} Total Connections", isMobile),
          const SizedBox(height: 16),
          if (_assignments.isEmpty) 
            _buildEmptyState("No assignments active.")
          else 
            ..._assignments.map((a) => _buildPairingTile(a, isMobile)),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w900, color: _deepNavy)),
        Text(subtitle, style: const TextStyle(color: _denim, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSelectionTool(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 40)],
      ),
      child: Column(
        children: [
          // Responsive layout for selection inputs
          if (isMobile) ...[
            _dropdownResident(),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.link, color: _sage)),
            _dropdownStaff(),
          ] else
            Row(
              children: [
                Expanded(child: _dropdownResident()),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.link, color: _sage, size: 30)),
                Expanded(child: _dropdownStaff()),
              ],
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _assign,
              style: FilledButton.styleFrom(
                backgroundColor: _deepNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_link_rounded, color: _cream),
              label: const Text("Create Connection", style: TextStyle(fontWeight: FontWeight.bold, color: _cream)),
            ),
          )
        ],
      ),
    );
  }

  Widget _dropdownResident() {
    return DropdownButtonFormField<int>(
      value: _selectedElderId,
      isExpanded: true,
      decoration: _inputDecoration("Resident", Icons.person_outline),
      dropdownColor: Colors.white,
      items: _availableElders.map<DropdownMenuItem<int>>((e) {
        return DropdownMenuItem<int>(
          value: (e['elder_id'] as num).toInt(),
          child: Text(e['elder_name'] ?? 'Resident', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedElderId = val),
    );
  }

  Widget _dropdownStaff() {
    return DropdownButtonFormField<int>(
      value: _selectedStaffId,
      isExpanded: true,
      decoration: _inputDecoration("Staff", Icons.badge_outlined),
      dropdownColor: Colors.white,
      items: _availableStaff.map<DropdownMenuItem<int>>((s) {
        return DropdownMenuItem<int>(
          value: (s['caregiver_id'] as num).toInt(),
          child: Text(s['name'] ?? 'Staff', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedStaffId = val),
    );
  }

  Widget _buildPairingTile(Map<String, dynamic> a, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: isMobile 
              ? Column(
                  children: [
                    _miniInfoTile(a['elder_name'] ?? 'Resident', "Resident", _sage),
                    const Divider(height: 16),
                    _miniInfoTile(a['caregiver_name'] ?? 'Staff', "Staff member", _denim),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _miniInfoTile(a['elder_name'] ?? 'Resident', "Resident", _sage)),
                    const Icon(Icons.chevron_right_rounded, color: _sage),
                    Expanded(child: _miniInfoTile(a['caregiver_name'] ?? 'Staff', "Staff member", _denim)),
                  ],
                ),
          ),
          IconButton(
            onPressed: () => _remove(a['elder_id'], a['caregiver_id']),
            icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _miniInfoTile(String name, String role, Color color) {
    return Row(
      children: [
        _miniAvatar(name[0], color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: _deepNavy, fontSize: 13), overflow: TextOverflow.ellipsis),
              Text(role, style: const TextStyle(fontSize: 9, color: _denim, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniAvatar(String char, Color color) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withOpacity(0.1),
      child: Text(char, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _denim, fontWeight: FontWeight.w600, fontSize: 13),
      prefixIcon: Icon(icon, color: _deepNavy, size: 18),
      filled: true,
      fillColor: _cream.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Center(child: Text(msg, style: const TextStyle(color: _denim, fontStyle: FontStyle.italic, fontSize: 13))),
    );
  }
}
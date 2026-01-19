import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  final AdminApi _api = AdminApi();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _all = [];
  String _roleFilter = 'all';

  final List<String> _statusOptions = const ['active', 'inactive', 'blocked'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _api.getActiveUsers();
      setState(() {
        _all = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _all = []; _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _all.where((u) {
      final role = _v(u['role'], fallback: '');
      if (_roleFilter != 'all' && role != _roleFilter) return false;
      if (q.isEmpty) return true;
      final searchableText = "${u['name']} ${u['email']} ${u['phone']} ${u['status']}".toLowerCase();
      return searchableText.contains(q);
    }).toList();
  }

  // 🎨 GUI STRENGTH: Enhanced Visual Identities
  IconData _roleIcon(String role, dynamic employmentType) {
    if (role == 'caregiver') {
      return employmentType == 'freelance' ? Icons.person_search : Icons.business_center;
    }
    switch (role) {
      case 'retirement_home': return Icons.corporate_fare;
      case 'family': return Icons.people_alt_outlined;
      case 'elder': return Icons.favorite_border;
      default: return Icons.person_outline;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'caregiver': return Colors.blue;
      case 'retirement_home': return Colors.purple;
      case 'family': return Colors.teal;
      case 'elder': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.green;
      case 'inactive': return Colors.orange;
      case 'blocked':
      case 'banned': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  // 🚀 GUI STRENGTH: Role-Specific Action Deep-Links
  Widget _buildRoleSpecificAction(Map<String, dynamic> user) {
    final role = _v(user['role']);
    if (role == 'elder') {
      return IconButton(
        icon: const Icon(Icons.location_on_outlined, color: Colors.red),
        tooltip: 'View Live Location',
        onPressed: () => Navigator.pushNamed(context, '/admin/gps-history', arguments: user['id']),
      );
    }
    if (role == 'caregiver' && user['ai_score'] != null) {
      return IconButton(
        icon: const Icon(Icons.psychology_outlined, color: Colors.blue),
        tooltip: 'View AI CV Analysis',
        onPressed: () => _showAIFeedback(user),
      );
    }
    return const SizedBox.shrink();
  }

  void _showAIFeedback(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("AI Evaluation: ${user['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Suitability Score: ${user['ai_score']}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user['ai_feedback'] ?? "No detailed feedback available."),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Users Management',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchHeader(),
                const SizedBox(height: 12),
                Expanded(child: _buildUserList()),
              ],
            ),
    );
  }

  Widget _buildSearchHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search (name / email / phone)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _roleFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Roles')),
                DropdownMenuItem(value: 'caregiver', child: Text('Caregivers')),
                DropdownMenuItem(value: 'family', child: Text('Families')),
                DropdownMenuItem(value: 'retirement_home', child: Text('Homes')),
                DropdownMenuItem(value: 'elder', child: Text('Elders')),
              ],
              onChanged: (v) => setState(() => _roleFilter = v ?? 'all'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_filtered.isEmpty) return const Center(child: Text('No users found.'));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final u = _filtered[index];
        final role = _v(u['role']);
        final status = _v(u['status'], fallback: 'active');
        final color = _statusColor(status);
        final employmentType = u['employment_type'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _roleColor(role).withOpacity(0.1),
              child: Icon(_roleIcon(role, employmentType), color: _roleColor(role)),
            ),
            title: Text(_v(u['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              role == 'caregiver' 
                  ? "Type: ${employmentType?.toUpperCase() ?? 'STAFF'}\nID: ${_v(u['id'])}"
                  : "Email: ${_v(u['email'])}\nID: ${_v(u['id'])}",
              style: const TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleSpecificAction(u), // 🚀 Contextual Action
                const SizedBox(width: 8),
                _buildStatusChip(status, color, u),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, Color color, Map<String, dynamic> user) {
    return PopupMenuButton<String>(
      onSelected: (v) => _confirmAndUpdateStatus(user: user, newStatus: v),
      itemBuilder: (_) => _statusOptions.map((s) => PopupMenuItem(value: s, child: Text("Set as $s"))).toList(),
      child: Chip(
        label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _confirmAndUpdateStatus({required Map<String, dynamic> user, required String newStatus}) async {
    final role = _v(user['role']);
    final id = _v(user['id']);
    final name = _v(user['name']);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Status'),
        content: Text('Set $name to "$newStatus"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _api.updateUserStatus(role: role, id: id, newStatus: newStatus);
      setState(() {
        final idx = _all.indexWhere((x) => _v(x['role']) == role && _v(x['id']) == id);
        if (idx != -1) _all[idx]['status'] = newStatus;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
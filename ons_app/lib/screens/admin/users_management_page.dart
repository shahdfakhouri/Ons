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

  // 🏛️ Analytics Helper: Counts for the Header
  int _getCount(String status) => _all.where((u) => _v(u['status']).toLowerCase() == status).length;

  IconData _roleIcon(String role, dynamic employmentType) {
    if (role == 'caregiver') {
      return employmentType == 'freelance' ? Icons.person_search : Icons.business_center;
    }
    switch (role) {
      case 'retirement_home': return Icons.corporate_fare;
      case 'family': return Icons.people_alt_outlined;
      case 'elder': return Icons.person_pin;
      default: return Icons.person_outline;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'caregiver': return Colors.blue;
      case 'retirement_home': return Colors.purple;
      case 'family': return Colors.teal;
      case 'elder': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'available': return Colors.green;
      case 'inactive': return Colors.orange;
      case 'blocked': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  Widget _buildRoleSpecificAction(Map<String, dynamic> user) {
    final role = _v(user['role']);
    if (role == 'elder') {
      return IconButton(
        icon: const Icon(Icons.location_on_outlined, color: Colors.red),
        onPressed: () => Navigator.pushNamed(context, '/admin/gps-history', arguments: user['id']),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AdminLayout(
      title: 'Users Management',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryHeader(colors),
                _buildSearchHeader(colors),
                const SizedBox(height: 12),
                Expanded(child: _buildUserList(colors)),
              ],
            ),
    );
  }

  // 📊 NEW: Summary Stats Header
  Widget _buildSummaryHeader(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatCard(label: "ACTIVE", count: _getCount('active') + _getCount('available'), color: Colors.green),
          _StatCard(label: "INACTIVE", count: _getCount('inactive'), color: Colors.orange),
          _StatCard(label: "TOTAL USERS", count: _all.length, color: Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surface, border: Border(bottom: BorderSide(color: colors.outlineVariant))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by name, email, or phone...',
                isDense: true,
                filled: true,
                fillColor: colors.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _roleFilter,
            underline: const SizedBox(),
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
    );
  }

  Widget _buildUserList(ColorScheme colors) {
    if (_filtered.isEmpty) return const Center(child: Text('No users found.'));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final u = _filtered[index];
        final role = _v(u['role']);
        final status = _v(u['status'], fallback: 'active');
        final color = _statusColor(status);
        final employmentType = u['employment_type'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _roleColor(role).withOpacity(0.1),
              child: Icon(_roleIcon(role, employmentType), color: _roleColor(role)),
            ),
            title: Text(_v(u['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // 🛠️ Role and Type Label
                Text(
                  role == 'caregiver' ? "TYPE: ${employmentType?.toUpperCase() ?? 'STAFF'}" : "ROLE: ${role.replaceAll('_', ' ').toUpperCase()}",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.secondary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(_v(u['email'] ?? u['phone']), style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleSpecificAction(u),
                const SizedBox(width: 4),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
        child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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
        title: const Text('Update User Status'),
        content: Text('Are you sure you want to set $name to "$newStatus"?'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// 🏛️ Reusable Component for Header Stats
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.2))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
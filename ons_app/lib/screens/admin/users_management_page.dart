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

  // Keep these simple; backend will accept what it accepts.
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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _api.getActiveUsers();
      setState(() {
        _all = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _all = [];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    return _all.where((u) {
      final role = _v(u['role'], fallback: '');
      if (_roleFilter != 'all' && role != _roleFilter) return false;

      if (q.isEmpty) return true;

      final name = _v(u['name']).toLowerCase();
      final email = _v(u['email']).toLowerCase();
      final phone = _v(u['phone']).toLowerCase();
      final status = _v(u['status']).toLowerCase();

      return name.contains(q) || email.contains(q) || phone.contains(q) || status.contains(q);
    }).toList();
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'caregiver':
        return Icons.badge_outlined;
      case 'retirement_home':
        return Icons.home_work_outlined;
      case 'family':
        return Icons.family_restroom_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'blocked':
      case 'banned':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _confirmAndUpdateStatus({
    required Map<String, dynamic> user,
    required String newStatus,
  }) async {
    final role = _v(user['role'], fallback: '');
    final id = _v(user['id'], fallback: '');
    final name = _v(user['name'], fallback: 'user');
    final oldStatus = _v(user['status'], fallback: '');

    if (role.isEmpty || id.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm status change'),
        content: Text('Change $name ($role) from "$oldStatus" to "$newStatus"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _api.updateUserStatus(role: role, id: id, newStatus: newStatus);

      // update locally without reloading
      setState(() {
        final idx = _all.indexWhere((x) => _v(x['role']) == role && _v(x['id']) == id);
        if (idx != -1) _all[idx]['status'] = newStatus;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $name to $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Users Management',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 260,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Search (name / email / phone / status)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            DropdownButton<String>(
                              value: _roleFilter,
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All roles')),
                                DropdownMenuItem(value: 'caregiver', child: Text('Caregivers')),
                                DropdownMenuItem(value: 'family', child: Text('Families')),
                                DropdownMenuItem(value: 'retirement_home', child: Text('Retirement homes')),
                              ],
                              onChanged: (v) => setState(() => _roleFilter = v ?? 'all'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                            Text('Total: ${_filtered.length}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text('No users found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final u = _filtered[index];

                                final role = _v(u['role'], fallback: '');
                                final id = _v(u['id'], fallback: '');
                                final name = _v(u['name']);
                                final email = _v(u['email'], fallback: '');
                                final phone = _v(u['phone'], fallback: '');
                                final status = _v(u['status'], fallback: 'active');

                                final color = _statusColor(status);

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Icon(_roleIcon(role)),
                                    title: Text('$name ($role)'),
                                    subtitle: Text(
                                      [
                                        if (email.isNotEmpty) 'Email: $email',
                                        if (phone.isNotEmpty) 'Phone: $phone',
                                        'ID: $id',
                                      ].join('\n'),
                                    ),
                                    trailing: Wrap(
                                      spacing: 10,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            status,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: color,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        DropdownButton<String>(
                                          value: _statusOptions.contains(status) ? status : _statusOptions.first,
                                          items: _statusOptions
                                              .map((s) => DropdownMenuItem(value: s, child: Text('Set: $s')))
                                              .toList(),
                                          onChanged: (v) {
                                            if (v == null || v == status) return;
                                            _confirmAndUpdateStatus(user: u, newStatus: v);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

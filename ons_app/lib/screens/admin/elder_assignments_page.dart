import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class ElderAssignmentsPage extends StatefulWidget {
  const ElderAssignmentsPage({super.key});

  @override
  State<ElderAssignmentsPage> createState() => _ElderAssignmentsPageState();
}

class _ElderAssignmentsPageState extends State<ElderAssignmentsPage> {
  final AdminApi _api = AdminApi();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _rows = [];

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
      final data = await _api.getElderAssignments();
      setState(() {
        _rows = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _rows = [];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;

    return _rows.where((r) {
      final elderName = _v(r['elder_name']).toLowerCase();
      final caregiverName = _v(r['caregiver_name'], fallback: '').toLowerCase();
      final homeName = _v(r['home_name'], fallback: '').toLowerCase();
      final caregiverStatus = _v(r['caregiver_status'], fallback: '').toLowerCase();
      final assignedAt = _v(r['assigned_at'], fallback: '').toLowerCase();

      return elderName.contains(q) ||
          caregiverName.contains(q) ||
          homeName.contains(q) ||
          caregiverStatus.contains(q) ||
          assignedAt.contains(q);
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Elder Assignments',
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
                              width: 320,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Search (elder / caregiver / home / status)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
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
                          ? const Center(child: Text('No assignments found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final r = _filtered[index];

                                final elderId = _v(r['elder_id']);
                                final elderName = _v(r['elder_name']);

                                final caregiverName =
                                    _v(r['caregiver_name'], fallback: 'Not assigned');
                                final caregiverStatus =
                                    _v(r['caregiver_status'], fallback: 'unknown');

                                final homeName =
                                    _v(r['home_name'], fallback: 'Not assigned');

                                final assignedAt = _v(r['assigned_at'], fallback: '-');

                                final statusColor = _statusColor(caregiverStatus);

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.elderly),
                                    title: Text('$elderName (ID: $elderId)'),
                                    subtitle: Text(
                                      [
                                        'Caregiver: $caregiverName',
                                        'Home: $homeName',
                                        'Assigned at: $assignedAt',
                                      ].join('\n'),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        caregiverStatus,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
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

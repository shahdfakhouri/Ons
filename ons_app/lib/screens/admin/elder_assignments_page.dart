import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String _settingFilter = 'All'; 
  String _order = 'Newest First';

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

  String _formatDate(String raw) {
    if (raw == '-' || raw.isEmpty) return 'Pending';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) { return raw; }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getElderAssignments();
      setState(() {
        _rows = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _rows = []; _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    
    List<Map<String, dynamic>> filteredList = _rows.where((r) {
      final matchesSearch = q.isEmpty || 
          _v(r['elder_name']).toLowerCase().contains(q) ||
          _v(r['caregiver_name']).toLowerCase().contains(q);
      
      // Setting Check: Logic assumes 'Private Home Care' or similar means Home-based
      final bool isHomeBased = _v(r['home_name']).toLowerCase().contains('private') || 
                               _v(r['home_name']).toLowerCase().contains('home care');

      bool matchesSetting = true;
      if (_settingFilter == 'Home-based') matchesSetting = isHomeBased;
      if (_settingFilter == 'Retirement Home') matchesSetting = !isHomeBased;

      return matchesSearch && matchesSetting;
    }).toList();

    filteredList.sort((a, b) {
      final dateA = DateTime.tryParse(_v(a['assigned_at'])) ?? DateTime(1900);
      final dateB = DateTime.tryParse(_v(b['assigned_at'])) ?? DateTime(1900);
      return _order == 'Newest First' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AdminLayout(
      title: 'Elder Assignments',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? _buildErrorView()
              : Column(
                  children: [
                    _buildHeader(colors),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text('No elders matching your filters.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) => _AssignmentCard(
                                row: _filtered[index],
                                date: _formatDate(_v(_filtered[index]['assigned_at'])),
                                v: _v,
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surface, border: Border(bottom: BorderSide(color: colors.outlineVariant))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search Elder or Caregiver...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: colors.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallDropdown("Setting", _settingFilter, ['All', 'Home-based', 'Retirement Home'], (v) => setState(() => _settingFilter = v!)),
              _buildSmallDropdown("Order", _order, ['Newest First', 'Oldest First'], (v) => setState(() => _order = v!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e == 'All' ? "$label: All" : e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
    ]));
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final String date;
  final Function v;

  const _AssignmentCard({required this.row, required this.date, required this.v});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isAtHome = v(row['home_name']).toLowerCase().contains('private') || 
                         v(row['home_name']).toLowerCase().contains('home care');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.outlineVariant.withOpacity(0.5))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PersonNode(name: v(row['elder_name']), label: "ELDER", icon: Icons.person_pin, color: Colors.blue),
                const Icon(Icons.link, color: Colors.grey),
                _PersonNode(
                  name: v(row['caregiver_name'], fallback: 'Searching...'),
                  label: "CAREGIVER",
                  icon: Icons.health_and_safety,
                  color: Colors.purple,
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Icon(isAtHome ? Icons.home : Icons.apartment, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(v(row['home_name'], fallback: 'Private Home'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isAtHome ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAtHome ? "HOME-BASED" : "FACILITY",
                    style: TextStyle(color: isAtHome ? Colors.green : Colors.orange, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Connection established: $date", style: TextStyle(fontSize: 11, color: colors.secondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonNode extends StatelessWidget {
  final String name, label;
  final IconData icon;
  final Color color;
  const _PersonNode({required this.name, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    ]);
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class HealthLogsPage extends StatefulWidget {
  const HealthLogsPage({super.key});

  @override
  State<HealthLogsPage> createState() => _HealthLogsPageState();
}

class _HealthLogsPageState extends State<HealthLogsPage> {
  final AdminApi _api = AdminApi();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  // UI filters
  String _query = '';
  String _typeFilter = 'All'; 
  String _riskFilter = 'All'; 
  bool _onlyWithLogs = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _typeFilter = 'All';
      _riskFilter = 'All';
      _onlyWithLogs = false;
      _searchController.clear();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _api.getHealthSummary();
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  int _i(dynamic x, {int fallback = 0}) {
    if (x == null) return fallback;
    if (x is int) return x;
    return int.tryParse(x.toString()) ?? fallback;
  }

  String _fmtTime(dynamic raw, {String fallback = 'Never'}) {
    if (raw == null || raw.toString().trim().isEmpty || raw.toString() == 'null') return fallback;
    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat('MMM dd, HH:mm').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  String _riskLabel(Map row) {
    final tempStr = _v(row['temperature'], fallback: '');
    final bp = _v(row['blood_pressure'], fallback: '');

    final t = double.tryParse(tempStr.replaceAll('°C', '').trim());
    if (t != null && t >= 38.0) return 'High Temp';

    final parts = bp.split('/');
    if (parts.isNotEmpty) {
      final sys = int.tryParse(parts.first.trim());
      if (sys != null && sys >= 140) return 'High BP';
    }
    return 'Normal';
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'High Temp':
      case 'High BP': return Colors.redAccent;
      default: return Colors.green;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'internal': return Colors.indigo;
      case 'freelance': return Colors.deepPurple;
      default: return Colors.blueGrey;
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _rows.where((row) {
      final elderName = _v(row['elder_name']).toLowerCase();
      final caregiverName = _v(row['caregiver_name']).toLowerCase();
      final homeName = _v(row['home_name']).toLowerCase();
      final employmentType = _v(row['employment_type']).toLowerCase();
      final risk = _riskLabel(row);
      final logsCount = _i(row['logs_count']);

      if (_onlyWithLogs && logsCount == 0) return false;
      if (_typeFilter != 'All' && employmentType != _typeFilter.toLowerCase()) return false;
      if (_riskFilter != 'All' && risk != _riskFilter) return false;
      if (q.isEmpty) return true;
      return elderName.contains(q) || caregiverName.contains(q) || homeName.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AdminLayout(
      title: 'Health Logs',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? _buildErrorView()
              : Column(
                  children: [
                    _buildTopHeader(colorScheme),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text('No results found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final row = _filtered[index];
                                final risk = _riskLabel(row);
                                return _EnhancedHealthCard(
                                  row: row,
                                  risk: risk,
                                  riskColor: _riskColor(risk),
                                  typeColor: _typeColor(_v(row['employment_type'])),
                                  fmtTime: _fmtTime,
                                  v: _v,
                                  i: _i,
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTopHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant, width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search patients or caregivers...',
                    isDense: true,
                    filled: true,
                    fillColor: colors.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChoiceChip('Risk', ['All', 'Normal', 'High BP', 'High Temp'], _riskFilter, (v) => setState(() => _riskFilter = v)),
                const SizedBox(width: 8),
                _buildChoiceChip('Staff', ['All', 'Internal', 'Freelance'], _typeFilter, (v) => setState(() => _typeFilter = v)),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Logged Only'),
                  selected: _onlyWithLogs,
                  onSelected: (v) => setState(() => _onlyWithLogs = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filtered.length} patients found',
                style: TextStyle(fontSize: 12, color: colors.secondary, fontWeight: FontWeight.w500),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_list_off, size: 16),
                label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, List<String> options, String current, Function(String) onSelect) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ChoiceChip(
            label: Text(opt),
            selected: current == opt,
            onSelected: (selected) {
              if (selected) onSelect(opt);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]));
  }
}

class _EnhancedHealthCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final String risk;
  final Color riskColor;
  final Color typeColor;
  final Function fmtTime;
  final Function v;
  final Function i;

  const _EnhancedHealthCard({
    required this.row,
    required this.risk,
    required this.riskColor,
    required this.typeColor,
    required this.fmtTime,
    required this.v,
    required this.i,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final elderName = v(row['elder_name']);
    final caregiverName = v(row['caregiver_name'], fallback: 'Unassigned');
    final homeName = v(row['home_name'], fallback: 'Home-based Care');
    final logsCount = i(row['logs_count']);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: riskColor.withOpacity(0.1),
                  child: Icon(Icons.person_outline, color: riskColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(elderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(homeName, style: TextStyle(color: colors.secondary, fontSize: 13)),
                    ],
                  ),
                ),
                _StatusPill(text: risk.toUpperCase(), color: riskColor),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricItem(label: 'Blood Pressure', value: v(row['blood_pressure']), icon: Icons.favorite_outline, color: Colors.red),
                _MetricItem(label: 'Sugar Level', value: v(row['blood_sugar']), icon: Icons.water_drop_outlined, color: Colors.blue),
                _MetricItem(label: 'Temp', value: v(row['temperature']), icon: Icons.thermostat_outlined, color: Colors.orange),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CAREGIVER', style: TextStyle(fontSize: 10, letterSpacing: 1, color: colors.secondary, fontWeight: FontWeight.bold)),
                      Text(caregiverName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                _TypeBadge(text: v(row['employment_type']).toString().toUpperCase(), color: typeColor),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Last Check-in', value: fmtTime(row['last_checkin'])),
                  const SizedBox(height: 6),
                  _InfoRow(label: 'Last Vitals Log', value: fmtTime(row['date'])),
                  const SizedBox(height: 6),
                  _InfoRow(label: 'Total Logs', value: logsCount.toString()),
                ],
              ),
            ),
            if (v(row['notes'], fallback: '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Notes: ${v(row['notes'])}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _TypeBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}
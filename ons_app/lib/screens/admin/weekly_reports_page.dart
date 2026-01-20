import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class WeeklyReportsPage extends StatefulWidget {
  const WeeklyReportsPage({super.key});

  @override
  State<WeeklyReportsPage> createState() => _WeeklyReportsPageState();
}

class _WeeklyReportsPageState extends State<WeeklyReportsPage> {
  final AdminApi _api = AdminApi();
  final TextEditingController _caregiverCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List _reports = [];

  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _caregiverCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? get _fromStr => _from == null ? null : _fmt(_from!);
  String? get _toStr => _to == null ? null : _fmt(_to!);

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _api.getReports(
        caregiverId: _caregiverCtrl.text.trim().isEmpty ? null : _caregiverCtrl.text.trim(),
        from: _fromStr,
        to: _toStr,
      );
      setState(() { _reports = rows; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _reports = []; _loading = false; });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: _from != null && _to != null 
          ? DateTimeRange(start: _from!, end: _to!) 
          : null,
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
      _load();
    }
  }

  void _clearFilters() {
    setState(() { _from = null; _to = null; _caregiverCtrl.clear(); });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AdminLayout(
      title: 'Weekly Performance Reports',
      child: Column(
        children: [
          _buildFilterHeader(colors),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _buildReportList(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _caregiverCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search by Caregiver ID...',
                prefixIcon: const Icon(Icons.person_search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(_from == null ? 'Filter Date' : '${_fmt(_from!)} - ${_fmt(_to!)}'),
            style: TextButton.styleFrom(foregroundColor: colors.primary),
          ),
          if (_from != null || _caregiverCtrl.text.isNotEmpty)
            IconButton(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear Filters',
            ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(ColorScheme colors) {
    if (_reports.isEmpty) {
      return const Center(child: Text('No weekly reports found for this period.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final r = _reports[index] as Map;
        final caregiver = _v(r['caregiver_name']);
        final elder = _v(r['elder_name']);
        final summary = _v(r['summary'], fallback: 'No summary provided for this week.');

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.article_outlined, color: colors.onPrimaryContainer),
            ),
            title: Text(
              '$elder — $caregiver',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Week of ${_v(r['week_start'])} to ${_v(r['week_end'])}',
              style: TextStyle(fontSize: 12, color: colors.secondary),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.notes, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  const Text('Weekly Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary,
                  style: const TextStyle(height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Filed on: ${_v(r['created_at'])}',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colors.outline),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
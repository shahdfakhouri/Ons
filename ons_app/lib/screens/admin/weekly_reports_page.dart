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
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? get _fromStr => _from == null ? null : _fmt(_from!);
  String? get _toStr => _to == null ? null : _fmt(_to!);

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
      final rows = await _api.getReports(
        caregiverId: _caregiverCtrl.text.trim().isEmpty ? null : _caregiverCtrl.text.trim(),
        from: _fromStr,
        to: _toStr,
      );

      setState(() {
        _reports = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _reports = [];
        _loading = false;
      });
    }
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _to = picked);
  }

  void _clearFilters() {
    setState(() {
      _from = null;
      _to = null;
      _caregiverCtrl.clear();
    });
    _load();
  }

  Future<void> _analyze(String reportId) async {
    try {
      await _api.analyzeReport(reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI analysis complete')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analyze failed: $e')),
      );
    }
  }

  Future<void> _exportCsv() async {
    // Backend exports ALL reports (no filters in your controller export route)
    try {
      await _api.exportWeeklyReportsCsv();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV fetched. (We’ll add browser download later.)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Weekly Reports',
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
                              width: 240,
                              child: TextField(
                                controller: _caregiverCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Caregiver ID (optional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickFrom,
                              icon: const Icon(Icons.date_range),
                              label: Text('From: ${_fromStr ?? '--'}'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickTo,
                              icon: const Icon(Icons.date_range),
                              label: Text('To: ${_toStr ?? '--'}'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.search),
                              label: const Text('Apply'),
                            ),
                            TextButton(
                              onPressed: _clearFilters,
                              child: const Text('Clear'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _exportCsv,
                              icon: const Icon(Icons.download),
                              label: const Text('Export CSV'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _reports.isEmpty
                          ? const Center(child: Text('No weekly reports found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reports.length,
                              itemBuilder: (context, index) {
                                final r = _reports[index] as Map;

                                final reportId = _v(r['report_id']);
                                final caregiverName = _v(r['caregiver_name']);
                                final elderName = _v(r['elder_name']);
                                final weekStart = _v(r['week_start']);
                                final weekEnd = _v(r['week_end']);
                                final createdAt = _v(r['created_at']);
                                final summary = _v(r['summary'], fallback: '');
                                final aiFeedback = _v(r['ai_feedback'], fallback: '');

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ExpansionTile(
                                    title: Text('$elderName — $caregiverName'),
                                    subtitle: Text('Week: $weekStart → $weekEnd\nCreated: $createdAt'),
                                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    children: [
                                      if (summary.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        const Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(summary),
                                      ],
                                      const SizedBox(height: 12),
                                      const Text('AI Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(aiFeedback.isEmpty ? 'Not analyzed yet.' : aiFeedback),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Wrap(
                                          spacing: 8,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () => _analyze(reportId),
                                              child: const Text('Analyze with AI'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementReportsPage extends StatefulWidget {
  const RetirementReportsPage({super.key});

  @override
  State<RetirementReportsPage> createState() => _RetirementReportsPageState();
}

class _RetirementReportsPageState extends State<RetirementReportsPage> with TickerProviderStateMixin {
  final _api = RetirementHomeApi();

  late final TabController _tabs;

  bool _loading = false;
  String? _error;

  Map<String, dynamic>? _currentReport; // report payload
  String? _currentType; // weekly/monthly
  String? _periodStart; // YYYY-MM-DD
  String? _periodEnd; // YYYY-MM-DD

  List<Map<String, dynamic>> _saved = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadSaved();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtNum(dynamic v) {
    if (v == null) return '-';
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }

  Future<void> _loadSaved() async {
    try {
      final list = await _api.getSavedReports();
      if (!mounted) return;
      setState(() => _saved = list);
    } catch (_) {
      // don’t block UI if saved list fails
    }
  }

  Future<void> _generateWeekly() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDate: now,
    );
    if (picked == null) return;

    final start = DateFormat('yyyy-MM-dd').format(picked);

    setState(() {
      _loading = true;
      _error = null;
      _currentReport = null;
      _currentType = 'weekly';
      _periodStart = null;
      _periodEnd = null;
    });

    try {
      final j = await _api.getWeeklyReport(startYYYYMMDD: start);
      final report = (j['report'] as Map?)?.cast<String, dynamic>();

      final period = (report?['period'] as Map?)?.cast<String, dynamic>() ?? {};
      final ps = (period['start'] ?? '').toString();
      final pe = (period['end'] ?? '').toString();

      setState(() {
        _currentReport = report;
        _periodStart = ps.isEmpty ? start : ps;
        _periodEnd = pe;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generateMonthly() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDate: DateTime(now.year, now.month, 1),
      helpText: 'Pick any day in the month',
    );
    if (picked == null) return;

    final month = DateFormat('yyyy-MM').format(picked);

    setState(() {
      _loading = true;
      _error = null;
      _currentReport = null;
      _currentType = 'monthly';
      _periodStart = null;
      _periodEnd = null;
    });

    try {
      final j = await _api.getMonthlyReport(monthYYYYMM: month);
      final report = (j['report'] as Map?)?.cast<String, dynamic>();

      final period = (report?['period'] as Map?)?.cast<String, dynamic>() ?? {};
      final ps = (period['start'] ?? '').toString();
      final pe = (period['end'] ?? '').toString();

      setState(() {
        _currentReport = report;
        _periodStart = ps;
        _periodEnd = pe;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveCurrent() async {
    if (_currentReport == null || _currentType == null || _periodStart == null || _periodEnd == null) {
      _snack('Generate a report first.');
      return;
    }

    try {
      await _api.saveReport(
        periodType: _currentType!,
        periodStart: _periodStart!,
        periodEnd: _periodEnd!,
        payload: _currentReport!,
      );
      _snack('Report saved ✅');
      await _loadSaved();
      _tabs.animateTo(2);
    } catch (e) {
      _snack('Save failed: $e');
    }
  }

  void _openSavedDetails(Map<String, dynamic> row) async {
    // Saved list only returns metadata in your controller.
    // If you want "open details", you can extend backend to return payload too.
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Saved report'),
        content: Text(
          'Report ID: ${row['report_id']}\n'
          'Type: ${row['period_type']}\n'
          'Start: ${row['period_start']}\n'
          'End: ${row['period_end']}\n'
          'Created: ${row['created_at']}\n\n'
          'If you want to open full report details here, update backend /saved to include payload.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _reportView() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_currentReport == null) {
      return const Center(child: Text('Generate a weekly or monthly report.'));
    }

    final r = _currentReport!;
    final period = (r['period'] as Map?)?.cast<String, dynamic>() ?? {};
    final elders = (r['elders'] as Map?)?.cast<String, dynamic>() ?? {};
    final incidents = (r['incidents'] as Map?)?.cast<String, dynamic>() ?? {};
    final health = (r['health'] as Map?)?.cast<String, dynamic>() ?? {};
    final payments = (r['payments'] as Map?)?.cast<String, dynamic>() ?? {};

    final byType = (incidents['by_type'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Period: ${period['start'] ?? _periodStart ?? '-'}  →  ${period['end'] ?? _periodEnd ?? '-'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _saveCurrent,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Elders
        Card(
          child: ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Elders in home'),
            trailing: Text('${elders['total'] ?? 0}', style: Theme.of(context).textTheme.titleLarge),
          ),
        ),

        const SizedBox(height: 12),

        // Incidents
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incidents', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Total: ${incidents['total'] ?? 0}'),
                const SizedBox(height: 10),
                if (byType.isEmpty)
                  const Text('No incident types recorded in this period.')
                else
                  Column(
                    children: byType.map((e) {
                      final m = (e as Map).cast<String, dynamic>();
                      return Row(
                        children: [
                          Expanded(child: Text((m['type'] ?? '-').toString())),
                          Text('${m['count'] ?? 0}'),
                        ],
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Health averages
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health averages', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Avg blood sugar: ${_fmtNum(health['avg_blood_sugar'])}'),
                Text('Avg temp: ${_fmtNum(health['avg_temp'])}'),
                Text('Avg systolic: ${_fmtNum(health['avg_systolic'])}'),
                Text('Avg diastolic: ${_fmtNum(health['avg_diastolic'])}'),
                Text('Total logs: ${health['total_logs'] ?? 0}'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Payments summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payments summary', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Total payments: ${payments['total_payments'] ?? 0}'),
                Text('Completed amount: ${payments['completed_amount'] ?? 0}'),
                Text('Pending count: ${payments['pending_count'] ?? 0}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _savedTab() {
    if (_saved.isEmpty) {
      return const Center(child: Text('No saved reports yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _saved.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final row = _saved[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.folder_open),
            title: Text(
              '${row['period_type'] ?? 'report'} • ${row['period_start'] ?? '-'} → ${row['period_end'] ?? '-'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Created: ${row['created_at'] ?? '-'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openSavedDetails(row),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Saved'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh saved',
            onPressed: _loadSaved,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Weekly
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _generateWeekly,
                        icon: const Icon(Icons.date_range),
                        label: const Text('Pick start date'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _reportView()),
            ],
          ),

          // Monthly
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _generateMonthly,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Pick month'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _reportView()),
            ],
          ),

          // Saved
          _savedTab(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final AdminApi _api = AdminApi();

  bool _loading = true;
  String? _error;

  Map<String, dynamic> _summary = {};
  List _alertsTimeline = [];
  List _revenueTimeline = [];
  List _userGrowth = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await _api.getAdminAnalytics();
      final alerts = await _api.getHealthAlertsTimeline();
      final revenue = await _api.getRevenueTimeline();
      final growth = await _api.getUserGrowthTimeline();

      setState(() {
        _summary = summary;
        _alertsTimeline = alerts;
        _revenueTimeline = revenue;
        _userGrowth = growth;
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

  int _asInt(dynamic x) => int.tryParse(_v(x, fallback: '0')) ?? 0;

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colors.primary.withOpacity(0.12),
              child: Icon(icon, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Admin Analytics',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadAll,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ===== SUMMARY =====
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, c) {
                        final wide = c.maxWidth > 900;
                        final cross = wide ? 3 : 1;

                        // Your controller returns arrays per key (because query returns rows)
                        final totalUsersByRole = (_summary['totalUsersByRole'] as List?) ?? [];
                        final activeCaregivers = ((_summary['activeCaregivers'] as List?) ?? []);
                        final pendingApprovals = ((_summary['pendingApprovals'] as List?) ?? []);
                        final elderAssignments = ((_summary['elderAssignments'] as List?) ?? []);
                        final weeklyReportsCount = ((_summary['weeklyReportsCount'] as List?) ?? []);

                        int caregivers = 0, families = 0, homes = 0, elders = 0;
                        for (final r in totalUsersByRole) {
                          final m = r as Map;
                          final role = _v(m['role']);
                          final count = _asInt(m['count']);
                          if (role == 'caregiver') caregivers = count;
                          if (role == 'family') families = count;
                          if (role == 'retirement_home') homes = count;
                          if (role == 'elder') elders = count;
                        }

                        final activeCg = activeCaregivers.isNotEmpty ? _asInt((activeCaregivers.first as Map)['active_caregivers']) : 0;
                        final pending = pendingApprovals.isNotEmpty ? _asInt((pendingApprovals.first as Map)['pending_approvals']) : 0;

                        final assigned = elderAssignments.isNotEmpty ? _asInt((elderAssignments.first as Map)['assigned']) : 0;
                        final unassigned = elderAssignments.isNotEmpty ? _asInt((elderAssignments.first as Map)['unassigned']) : 0;

                        final reports = weeklyReportsCount.isNotEmpty ? _asInt((weeklyReportsCount.first as Map)['weekly_reports']) : 0;

                        final items = [
                          _statCard(title: 'Caregivers', value: '$caregivers', icon: Icons.badge_outlined),
                          _statCard(title: 'Families', value: '$families', icon: Icons.family_restroom_outlined),
                          _statCard(title: 'Retirement homes', value: '$homes', icon: Icons.home_work_outlined),
                          _statCard(title: 'Elders', value: '$elders', icon: Icons.elderly),
                          _statCard(title: 'Active caregivers', value: '$activeCg', icon: Icons.check_circle_outline),
                          _statCard(title: 'Pending approvals', value: '$pending', icon: Icons.hourglass_top),
                          _statCard(title: 'Assigned elders', value: '$assigned', icon: Icons.assignment_ind_outlined),
                          _statCard(title: 'Unassigned elders', value: '$unassigned', icon: Icons.assignment_late_outlined),
                          _statCard(title: 'Weekly reports', value: '$reports', icon: Icons.article_outlined),
                        ];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cross,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: wide ? 2.8 : 3.2,
                          ),
                          itemBuilder: (_, i) => items[i],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ===== HEALTH ALERTS TIMELINE =====
                    Row(
                      children: [
                        Text(
                          'Health Alerts (last 30 days)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _loadAll,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _alertsTimeline.isEmpty
                        ? const Text('No alert timeline data.')
                        : _TimelineTable(
                            headers: const ['Day', 'Critical', 'Warning', 'Total'],
                            rows: _alertsTimeline.map((e) {
                              final m = e as Map;
                              return [
                                _v(m['day']),
                                _v(m['critical_count'], fallback: '0'),
                                _v(m['warning_count'], fallback: '0'),
                                _v(m['total_alerts'], fallback: '0'),
                              ];
                            }).toList(),
                          ),

                    const SizedBox(height: 24),

                    // ===== REVENUE TIMELINE =====
                    Text(
                      'Revenue (last 30 days)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _revenueTimeline.isEmpty
                        ? const Text('No revenue timeline data.')
                        : _TimelineTable(
                            headers: const ['Day', 'Platform revenue', 'Payouts'],
                            rows: _revenueTimeline.map((e) {
                              final m = e as Map;
                              return [
                                _v(m['day']),
                                _v(m['platform_revenue'], fallback: '0'),
                                _v(m['payouts'], fallback: '0'),
                              ];
                            }).toList(),
                          ),

                    const SizedBox(height: 24),

                    // ===== USER GROWTH =====
                    Text(
                      'User Growth (last 12 months)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _userGrowth.isEmpty
                        ? const Text('No user growth data.')
                        : _TimelineTable(
                            headers: const ['Month', 'Role', 'Count'],
                            rows: _userGrowth.map((e) {
                              final m = e as Map;
                              return [
                                _v(m['ym']),
                                _v(m['role']),
                                _v(m['count'], fallback: '0'),
                              ];
                            }).toList(),
                          ),
                  ],
                ),
    );
  }
}

class _TimelineTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const _TimelineTable({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
          rows: rows
              .map(
                (r) => DataRow(
                  cells: r.map((c) => DataCell(Text(c))).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

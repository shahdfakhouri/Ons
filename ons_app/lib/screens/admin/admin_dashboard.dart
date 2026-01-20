import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';

import 'package:ons_app/screens/admin/approve_caregivers.dart';
import 'package:ons_app/screens/admin/approve_retirement_homes.dart';
import 'package:ons_app/screens/admin/health_logs_page.dart';
import 'package:ons_app/screens/admin/matching_overview_page.dart';
import 'package:ons_app/screens/admin/admin_notifications_page.dart';
import 'package:ons_app/screens/admin/payments_page.dart';

import 'package:ons_app/screens/admin/weekly_reports_page.dart';
import 'package:ons_app/screens/admin/users_management_page.dart';
import 'package:ons_app/screens/admin/elder_assignments_page.dart';
//import 'package:ons_app/screens/admin/gps_overview_page.dart';
import 'package:ons_app/screens/admin/admin_analytics_page.dart';

import 'package:ons_app/services/admin_api.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _api = AdminApi();

  bool _loading = true;
  String? _error;

  int pendingCaregivers = 0;
  int pendingHomes = 0;
  int openHealthAlerts = 0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<void> _loadOverview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // must return the "overview" object from backend
      final overview = await _api.overviewFull();

      final users = (overview['users'] as Map?) ?? {};
      final health = (overview['health'] as Map?) ?? {};

      setState(() {
        pendingCaregivers = _asInt(users['pending_caregivers']);
        pendingHomes = _asInt(users['pending_homes']);
        openHealthAlerts = _asInt(health['open_alerts']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _navReplace(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AdminLayout(
      title: 'Dashboard',
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
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadOverview,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Admin',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.deepNavy,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monitor the platform, approve partners, and keep Ons running smoothly.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withOpacity(0.7),
                            ),
                      ),
                      const SizedBox(height: 20),

                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _StatusChip(
                            label: 'Pending caregivers',
                            value: pendingCaregivers.toString(),
                          ),
                          _StatusChip(
                            label: 'Pending homes',
                            value: pendingHomes.toString(),
                          ),
                          _StatusChip(
                            label: 'Open health alerts',
                            value: openHealthAlerts.toString(),
                          ),
                          ActionChip(
                            label: const Text('Refresh'),
                            avatar: const Icon(Icons.refresh, size: 18),
                            onPressed: _loadOverview,
                            backgroundColor: AppTheme.sage.withOpacity(0.14),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          final crossAxisCount = isWide ? 2 : 1;

                          final tiles = <_AdminTile>[
                            _AdminTile(
                              icon: Icons.badge_outlined,
                              title: 'Approve Caregivers',
                              subtitle: 'Review CVs & approve new caregivers.',
                              onTap: () => _navReplace(
                                context,
                                const ApproveCaregiversPage(),
                              ),
                            ),
                            _AdminTile(
                              icon: Icons.home_work_outlined,
                              title: 'Approve Retirement Homes',
                              subtitle: 'Review homes & approve partners.',
                              onTap: () => _navReplace(
                                context,
                                const ApproveRetirementHomesPage(),
                              ),
                            ),
                            _AdminTile(
                              icon: Icons.groups_3_outlined,
                              title: 'Matching Overview',
                              subtitle: 'Monitor matches & approve/reject.',
                              onTap: () => _navReplace(
                                context,
                                const MatchingOverviewPage(),
                              ),
                            ),
                            _AdminTile(
                              icon: Icons.favorite_border,
                              title: 'Health Logs',
                              subtitle: 'Health summaries & last check-ins.',
                              onTap: () => _navReplace(
                                context,
                                const HealthLogsPage(),
                              ),
                            ),
                            _AdminTile(
                              icon: Icons.notifications_active_outlined,
                              title: 'Notifications',
                              subtitle: 'Health alerts & system messages.',
                              onTap: () => _navReplace(
                                context,
                                const AdminNotificationsPage(),
                              ),
                            ),
                            _AdminTile(
                              icon: Icons.payments_outlined,
                              title: 'Payments & Payouts',
                              subtitle: 'Financial overview & payments stats.',
                              onTap: () => _navReplace(
                                context,
                                const PaymentsPage(),
                              ),
                            ),

                            // ======= Missing backend features (now included) =======
                            _AdminTile(
                              icon: Icons.article_outlined,
                              title: 'Weekly Reports',
                              subtitle: 'Filter reports & analyze with AI.',
                              onTap: () => _navReplace(
                                context,
                                const WeeklyReportsPage(),
                              ),
                            ),
                            _AdminTile(
                              icon: Icons.manage_accounts_outlined,
                              title: 'Users Management',
                              subtitle: 'Search users & update account status.',
                              onTap: () => _navReplace(
                                context,
                                const UsersManagementPage(),
                              ),
                            ),
                            _AdminTile(
                              icon: Icons.assignment_ind_outlined,
                              title: 'Elder Assignments',
                              subtitle: 'See elder ↔ caregiver/home assignments.',
                              onTap: () => _navReplace(
                                context,
                                const ElderAssignmentsPage(),
                              ),
                            ),
                           // _AdminTile(
                             // icon: Icons.location_on_outlined,
                              //title: 'GPS Overview',
                              //subtitle: 'Last seen locations + history.',
                              //onTap: () => _navReplace(
                                //context,
                               // const GpsOverviewPage(),
                             // ),
                           // ),
                            _AdminTile(
                              icon: Icons.analytics_outlined,
                              title: 'Analytics',
                              subtitle: 'Platform metrics + timelines.',
                              onTap: () => _navReplace(
                                context,
                                const AdminAnalyticsPage(),
                              ),
                            ),
                          ];

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: isWide ? 2.6 : 2.2,
                            ),
                            itemCount: tiles.length,
                            itemBuilder: (_, i) => tiles[i],
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: AppTheme.sage.withOpacity(0.16),
      side: BorderSide.none,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.denim,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.deepNavy.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_AdminTile> createState() => _AdminTileState();
}

class _AdminTileState extends State<_AdminTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: _hovered
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  )
                ]
              : [
                  BoxShadow(
                    color: colors.onSurface.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.sage.withOpacity(0.35),
                    child: Icon(widget.icon, size: 26, color: AppTheme.denim),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepNavy,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

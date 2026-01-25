import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

// Import all your specific pages for navigation here
import 'package:ons_app/screens/admin/approve_caregivers.dart';
import 'package:ons_app/screens/admin/approve_retirement_homes.dart';
import 'package:ons_app/screens/admin/matching_overview_page.dart';
import 'package:ons_app/screens/admin/health_logs_page.dart';
import 'package:ons_app/screens/admin/admin_notifications_page.dart';
import 'package:ons_app/screens/admin/payments_page.dart';
import 'package:ons_app/screens/admin/weekly_reports_page.dart';
import 'package:ons_app/screens/admin/users_management_page.dart';
import 'package:ons_app/screens/admin/elder_assignments_page.dart';
import 'package:ons_app/screens/admin/admin_analytics_page.dart';

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

  int _asInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;

  Future<void> _loadOverview() async {
    setState(() { _loading = true; _error = null; });
    try {
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
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _navReplace(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Dashboard',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadOverview)
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _WelcomeHeader(),
                      const SizedBox(height: 20),
                      
                      // Status Chips - Wrap handles row breaks automatically
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatusChip(label: 'Pending caregivers', value: pendingCaregivers.toString()),
                          _StatusChip(label: 'Pending homes', value: pendingHomes.toString()),
                          _StatusChip(label: 'Open health alerts', value: openHealthAlerts.toString()),
                          ActionChip(
                            label: const Text('Refresh'),
                            onPressed: _loadOverview,
                            avatar: const Icon(Icons.refresh, size: 16),
                            backgroundColor: AppTheme.sage.withOpacity(0.14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Responsive Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
                          double aspectRatio = constraints.maxWidth > 600 ? 2.5 : 1.8;

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: aspectRatio,
                            children: [
                              _AdminTile(
                                icon: Icons.badge_outlined,
                                title: 'Approve Caregivers',
                                subtitle: 'Review CVs & accounts.',
                                onTap: () => _navReplace(context, const ApproveCaregiversPage()),
                              ),
                              _AdminTile(
                                icon: Icons.home_work_outlined,
                                title: 'Approve Retirement Homes',
                                subtitle: 'Review homes & partners.',
                                onTap: () => _navReplace(context, const ApproveRetirementHomesPage()),
                              ),
                              _AdminTile(
                                icon: Icons.groups_3_outlined,
                                title: 'Matching Overview',
                                subtitle: 'Monitor & approve matches.',
                                onTap: () => _navReplace(context, const MatchingOverviewPage()),
                              ),
                              _AdminTile(
                                icon: Icons.favorite_border,
                                title: 'Health Logs',
                                subtitle: 'Summaries & last check-ins.',
                                onTap: () => _navReplace(context, const HealthLogsPage()),
                              ),
                              _AdminTile(
                                icon: Icons.notifications_active_outlined,
                                title: 'Notifications',
                                subtitle: 'System alerts & messages.',
                                onTap: () => _navReplace(context, const AdminNotificationsPage()),
                              ),
                              _AdminTile(
                                icon: Icons.payments_outlined,
                                title: 'Payments',
                                subtitle: 'Financial overview & stats.',
                                onTap: () => _navReplace(context, const PaymentsPage()),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}

// --- Supporting UI Components ---

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome, Admin', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.deepNavy, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Monitor the platform and keep Ons running smoothly.', style: TextStyle(color: Colors.black.withOpacity(0.6))),
      ],
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
      backgroundColor: AppTheme.sage.withOpacity(0.16),
      side: BorderSide.none,
      label: Text('$value $label', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.denim)),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppTheme.sage.withOpacity(0.2), child: Icon(icon, color: AppTheme.denim)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepNavy)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
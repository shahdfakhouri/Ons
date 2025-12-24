import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/screens/admin/admin_dashboard.dart';
import 'package:ons_app/screens/admin/approve_caregivers.dart';
import 'package:ons_app/screens/admin/approve_retirement_homes.dart';
import 'package:ons_app/screens/admin/health_logs_page.dart';
import 'package:ons_app/screens/admin/matching_overview_page.dart';
import 'package:ons_app/screens/admin/notifications_page.dart';
import 'package:ons_app/screens/admin/payments_page.dart';
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/screens/auth/login_page.dart';
import 'package:ons_app/screens/admin/weekly_reports_page.dart';
import 'package:ons_app/screens/admin/users_management_page.dart';
import 'package:ons_app/screens/admin/elder_assignments_page.dart';
import 'package:ons_app/screens/admin/gps_overview_page.dart';
import 'package:ons_app/screens/admin/admin_analytics_page.dart';


class AdminLayout extends StatelessWidget {
  final String title;
  final Widget child;

  const AdminLayout({
    super.key,
    required this.title,
    required this.child,
  });

  void _logout(BuildContext context) {
    AuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,

        backgroundColor: AppTheme.cream,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            Text(
              'Ons Admin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.sage.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: AppTheme.denim,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Admin',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.deepNavy,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile (coming soon)',
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
            color: colors.onSurface,
          ),
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.deepNavy,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // =============== BODY ===============
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar on the left
          _AdminSidebar(currentTitle: title),

          // Main content on the right
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.deepNavy,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // the page widget; it gets bounded height
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== SIDEBAR ==================

class _AdminSidebar extends StatelessWidget {
  final String currentTitle;

  const _AdminSidebar({required this.currentTitle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _SidebarItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: currentTitle == 'Dashboard',
              onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardPage(),
                        ),
                      );
                    },
            ),
            _SidebarItem(
              icon: Icons.groups_3_outlined,
              label: 'Matching overview',
              selected: currentTitle == 'Matching overview',
             onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MatchingOverviewPage(),
                        ),
                      );
                    },
            ),
            _SidebarItem(
              icon: Icons.badge_outlined,
              label: 'Approve caregivers',
              selected: currentTitle == 'Approve caregivers',
              onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApproveCaregiversPage(),
                        ),
                      );
                    },
            ),
            _SidebarItem(
              icon: Icons.home_work_outlined,
              label: 'Approve homes',
              selected: currentTitle == 'Approve homes',
             onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApproveRetirementHomesPage(),
                        ),
                      );
                    },
            ),
            _SidebarItem(
              icon: Icons.favorite_border,
              label: 'Health logs',
              selected: currentTitle == 'Health logs',
              onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HealthLogsPage(),
                        ),
                      );
                    },
            ),
            _SidebarItem(
              icon: Icons.payments_outlined,
              label: 'Payments',
              selected: currentTitle == 'Payments',
            onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaymentsPage(),
                        ),
                      );
                    },
            ),
            _SidebarItem(
              icon: Icons.notifications_active_outlined,
              label: 'Notifications',
              selected: currentTitle == 'Notifications',
              onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                    },
            ),

            _SidebarItem(
  icon: Icons.article_outlined,
  label: 'Weekly reports',
  selected: currentTitle == 'Weekly Reports',
  onTap: () {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WeeklyReportsPage()),
    );
  },
),


_SidebarItem(
  icon: Icons.manage_accounts_outlined,
  label: 'Users management',
  selected: currentTitle == 'Users Management',
  onTap: () {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UsersManagementPage()),
    );
  },
),

_SidebarItem(
  icon: Icons.assignment_ind_outlined,
  label: 'Elder assignments',
  selected: currentTitle == 'Elder Assignments',
  onTap: () {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ElderAssignmentsPage()),
    );
  },
),


_SidebarItem(
  icon: Icons.location_on_outlined,
  label: 'GPS overview',
  selected: currentTitle == 'GPS Overview',
  onTap: () {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GpsOverviewPage()),
    );
  },
),

_SidebarItem(
  icon: Icons.analytics_outlined,
  label: 'Analytics',
  selected: currentTitle == 'Admin Analytics',
  onTap: () {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminAnalyticsPage()),
    );
  },
),



          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        selected ? AppTheme.denim : AppTheme.deepNavy.withOpacity(0.8);

    return Material(
      color: selected ? AppTheme.sage.withOpacity(0.25) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

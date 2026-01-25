import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/screens/auth/login_page.dart';

// Import all your admin pages here so the sidebar navigation works
import 'package:ons_app/screens/admin/admin_dashboard.dart';
import 'package:ons_app/screens/admin/approve_caregivers.dart';
import 'package:ons_app/screens/admin/approve_retirement_homes.dart';
import 'package:ons_app/screens/admin/health_logs_page.dart';
import 'package:ons_app/screens/admin/matching_overview_page.dart';
import 'package:ons_app/screens/admin/payments_page.dart';
import 'package:ons_app/screens/admin/weekly_reports_page.dart';
import 'package:ons_app/screens/admin/users_management_page.dart';
import 'package:ons_app/screens/admin/elder_assignments_page.dart';
import 'package:ons_app/screens/admin/admin_analytics_page.dart';
import 'package:ons_app/screens/admin/admin_notifications_page.dart';

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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 1050; // Threshold for mobile/tablet

    return Scaffold(
      backgroundColor: AppTheme.cream,
      // Drawer only appears on mobile
      drawer: isMobile ? Drawer(child: _AdminSidebarContent(currentTitle: title)) : null,
      appBar: AppBar(
        automaticallyImplyLeading: isMobile, // Show hamburger icon only on mobile
        iconTheme: const IconThemeData(color: AppTheme.deepNavy),
        backgroundColor: AppTheme.cream,
        elevation: 0,
        titleSpacing: isMobile ? 0 : 24,
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
            _AdminBadge(),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline, color: AppTheme.deepNavy),
          ),
          if (!isMobile) // Only show text label on desktop
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.deepNavy),
            )
          else
            IconButton(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 18, color: AppTheme.deepNavy),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar: Only show on Desktop
          if (!isMobile)
            SizedBox(
              width: 260,
              child: _AdminSidebarContent(currentTitle: title),
            ),

          // Main content
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 32),
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

class _AdminSidebarContent extends StatelessWidget {
  final String currentTitle;
  const _AdminSidebarContent({required this.currentTitle});

  void _nav(BuildContext context, Widget page) {
    if (Navigator.canPop(context)) Navigator.pop(context); // Close drawer if open
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListView(
        children: [
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: currentTitle == 'Dashboard',
            onTap: () => _nav(context, const AdminDashboardPage()),
          ),
          _SidebarItem(
            icon: Icons.groups_3_outlined,
            label: 'Matching overview',
            selected: currentTitle == 'Matching overview',
            onTap: () => _nav(context, const MatchingOverviewPage()),
          ),
          _SidebarItem(
            icon: Icons.badge_outlined,
            label: 'Approve caregivers',
            selected: currentTitle == 'Approve caregivers',
            onTap: () => _nav(context, const ApproveCaregiversPage()),
          ),
          _SidebarItem(
            icon: Icons.home_work_outlined,
            label: 'Approve homes',
            selected: currentTitle == 'Approve homes',
            onTap: () => _nav(context, const ApproveRetirementHomesPage()),
          ),
          _SidebarItem(
            icon: Icons.favorite_border,
            label: 'Health logs',
            selected: currentTitle == 'Health logs',
            onTap: () => _nav(context, const HealthLogsPage()),
          ),
          _SidebarItem(
            icon: Icons.payments_outlined,
            label: 'Payments',
            selected: currentTitle == 'Payments',
            onTap: () => _nav(context, const PaymentsPage()),
          ),
          _SidebarItem(
            icon: Icons.notifications_active_outlined,
            label: 'Notifications',
            selected: currentTitle == 'Notifications',
            onTap: () => _nav(context, const AdminNotificationsPage()),
          ),
          _SidebarItem(
            icon: Icons.article_outlined,
            label: 'Weekly reports',
            selected: currentTitle == 'Weekly Reports',
            onTap: () => _nav(context, const WeeklyReportsPage()),
          ),
          _SidebarItem(
            icon: Icons.manage_accounts_outlined,
            label: 'Users management',
            selected: currentTitle == 'Users Management',
            onTap: () => _nav(context, const UsersManagementPage()),
          ),
          _SidebarItem(
            icon: Icons.assignment_ind_outlined,
            label: 'Elder assignments',
            selected: currentTitle == 'Elder Assignments',
            onTap: () => _nav(context, const ElderAssignmentsPage()),
          ),
          _SidebarItem(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            selected: currentTitle == 'Admin Analytics',
            onTap: () => _nav(context, const AdminAnalyticsPage()),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected ? AppTheme.denim : AppTheme.deepNavy.withOpacity(0.8);
    return Material(
      color: selected ? AppTheme.sage.withOpacity(0.25) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(color: textColor, fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.sage.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
      child: const Text('Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.deepNavy)),
    );
  }
}
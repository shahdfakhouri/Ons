import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/screens/auth/login_page.dart';

// caregiver screens
import 'package:ons_app/screens/caregiver/caregiver_dashboard.dart';
import 'package:ons_app/screens/caregiver/upcoming_visits_page.dart';
import 'package:ons_app/screens/caregiver/assigned_elders_page.dart';
import 'package:ons_app/screens/caregiver/caregiver_health_logs_page.dart';
import 'package:ons_app/screens/caregiver/caregiver_payments_page.dart';

class CaregiverLayout extends StatelessWidget {
  final String title;
  final Widget child;

  const CaregiverLayout({
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
        backgroundColor: AppTheme.cream,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            Text(
              'Ons Caregiver',
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
                    Icons.volunteer_activism_outlined,
                    size: 18,
                    color: AppTheme.denim,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Caregiver',
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
            tooltip: 'Profile',
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

      // body with sidebar + main content
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CaregiverSidebar(currentTitle: title),
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

class _CaregiverSidebar extends StatelessWidget {
  final String currentTitle;

  const _CaregiverSidebar({required this.currentTitle});

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaregiverDashboardPage(),
                  ),
                );
              },
            ),
            _SidebarItem(
              icon: Icons.event_available_outlined,
              label: 'Upcoming visits',
              selected: currentTitle == 'Upcoming visits',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UpcomingVisitsPage(),
                  ),
                );
              },
            ),
            _SidebarItem(
              icon: Icons.groups_2_outlined,
              label: 'Assigned elders',
              selected: currentTitle == 'Assigned elders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssignedEldersPage(),
                  ),
                );
              },
            ),
            _SidebarItem(
              icon: Icons.favorite_border,
              label: 'Health logs',
              selected: currentTitle == 'Health logs',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaregiverHealthLogsPage(),
                  ),
                );
              },
            ),
            _SidebarItem(
              icon: Icons.payments_outlined,
              label: 'Payments',
              selected: currentTitle == 'Payments',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaregiverPaymentsPage(),
                  ),
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
    final textColor = selected ? AppTheme.denim : AppTheme.deepNavy.withOpacity(0.8);

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
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

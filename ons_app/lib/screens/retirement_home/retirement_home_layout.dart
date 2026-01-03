import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/screens/auth/login_page.dart';

import 'retirement_home_dashboard.dart';
import 'elders_monitoring_page.dart';
import 'caregivers_page.dart';
import 'center_page.dart';
import 'finance_page.dart';
import 'visits_page.dart';

class RetirementHomeLayout extends StatelessWidget {
  final String title;
  final Widget child;

  const RetirementHomeLayout({
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
              'Ons Home',
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
                  const Icon(Icons.home_work_outlined, size: 18, color: AppTheme.denim),
                  const SizedBox(width: 6),
                  Text(
                    'Retirement home',
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
            tooltip: 'Profile (later)',
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
            color: colors.onSurface,
          ),
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.deepNavy),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HomeSidebar(currentTitle: title),
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

class _HomeSidebar extends StatelessWidget {
  final String currentTitle;

  const _HomeSidebar({required this.currentTitle});

  void _go(BuildContext context, Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
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
              onTap: () => _go(context, const RetirementHomeDashboardPage()),
            ),
            _SidebarItem(
              icon: Icons.monitor_heart_outlined,
              label: 'Elders monitoring',
              selected: currentTitle == 'Elders monitoring',
              onTap: () => _go(context, const EldersMonitoringPage()),
            ),
            _SidebarItem(
              icon: Icons.groups_outlined,
              label: 'Caregivers',
              selected: currentTitle == 'Caregivers',
              onTap: () => _go(context, const CaregiversPage()),
            ),
            _SidebarItem(
              icon: Icons.event_outlined,
              label: 'Visits',
              selected: currentTitle == 'Visits',
              onTap: () => _go(context, const VisitsPage()),
            ),
            _SidebarItem(
              icon: Icons.warning_amber_outlined,
              label: 'Center',
              selected: currentTitle == 'Center',
              onTap: () => _go(context, const CenterPage()),
            ),
            _SidebarItem(
              icon: Icons.payments_outlined,
              label: 'Finance',
              selected: currentTitle == 'Finance',
              onTap: () => _go(context, const FinancePage()),
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

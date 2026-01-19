import 'package:flutter/material.dart';

import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/screens/auth/login_page.dart';

import 'pages/dashboard_page.dart';
import 'pages/caregivers_page.dart';
import 'pages/assignments_page.dart';
import 'pages/elders_page.dart';
import 'pages/alerts_page.dart';
import 'pages/emergencies_page.dart';
import 'pages/shifts_page.dart';
import 'pages/daily_summaries_page.dart';
import 'pages/reports_page.dart';
import 'pages/payments_page.dart';
import 'pages/transactions_page.dart';
import 'pages/incidents_page.dart';
import 'pages/notes_page.dart';

class RetirementHomeLayout extends StatefulWidget {
  final int initialIndex;
  const RetirementHomeLayout({super.key, this.initialIndex = 0});

  @override
  State<RetirementHomeLayout> createState() => _RetirementHomeLayoutState();
}

class _RetirementHomeLayoutState extends State<RetirementHomeLayout> {
  late int _index;

  static const _titles = [
    'Dashboard',
    'Caregivers',
    'Assignments',
    'Elders',
    'Alerts',
    'Emergencies',
    'Shifts',
    'Daily Summaries',
    'Reports',
    'Payments',
    'Transactions',
    'Incidents',
    'Notes',
  ];

  final _pages = const [
    RetirementDashboardPage(),
    RetirementCaregiversPage(),
    RetirementAssignmentsPage(),
    RetirementEldersPage(),
    RetirementAlertsPage(),
    RetirementEmergenciesPage(),
    RetirementShiftsPage(),
    RetirementDailySummariesPage(),
    RetirementReportsPage(),
    RetirementPaymentsPage(),
    RetirementTransactionsPage(),
    RetirementIncidentsPage(),
    RetirementNotesPage(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  void _logout(BuildContext context) {
    AuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ✅ only close drawer when we are in mobile drawer mode
  void _goTo(int i, {bool closeDrawer = false}) {
    setState(() => _index = i);
    if (closeDrawer) Navigator.of(context).pop(); // closes the drawer only
  }

  Widget _nav(ColorScheme cs, {required bool closeDrawerOnSelect}) {
    return NavigationDrawer(
      selectedIndex: _index,
      onDestinationSelected: (i) => _goTo(i, closeDrawer: closeDrawerOnSelect),
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Retirement Home',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Current: ${_titles[_index]}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),

        const NavigationDrawerDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge),
          label: Text('Caregivers'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.link_outlined),
          selectedIcon: Icon(Icons.link),
          label: Text('Assignments'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Elders'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.notifications_none),
          selectedIcon: Icon(Icons.notifications),
          label: Text('Alerts'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.warning_amber_outlined),
          selectedIcon: Icon(Icons.warning),
          label: Text('Emergencies'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.schedule_outlined),
          selectedIcon: Icon(Icons.schedule),
          label: Text('Shifts'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.today_outlined),
          selectedIcon: Icon(Icons.today),
          label: Text('Summaries'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: Text('Reports'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.payments_outlined),
          selectedIcon: Icon(Icons.payments),
          label: Text('Payments'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('Transactions'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.report_gmailerrorred_outlined),
          selectedIcon: Icon(Icons.report),
          label: Text('Incidents'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.note_alt_outlined),
          selectedIcon: Icon(Icons.note_alt),
          label: Text('Notes'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    AppBar topBar() => AppBar(
          title: Text(_titles[_index]),
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
            ),
            const SizedBox(width: 12),
          ],
        );

    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 900;

        if (isWide) {
          return Scaffold(
            appBar: topBar(),
            body: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: _nav(cs, closeDrawerOnSelect: false), // ✅ don't pop routes
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _pages[_index],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: topBar(),
          drawer: Drawer(
            child: SafeArea(
              child: _nav(cs, closeDrawerOnSelect: true), // ✅ close drawer only
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: _pages[_index],
          ),
        );
      },
    );
  }
}

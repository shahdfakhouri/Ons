import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/caregivers_page.dart';
import 'pages/assignments_page.dart';
import 'pages/elders_page.dart';
import 'pages/alerts_page.dart';
import 'pages/emergencies_page.dart';
import 'pages/shifts_page.dart';
import 'pages/daily_summaries_page.dart';
import 'pages/payments_page.dart';
import 'pages/transactions_page.dart';
import 'pages/incidents_page.dart';

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
    'Payments',
    'Transactions',
    'Incidents',
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
    RetirementPaymentsPage(),
    RetirementTransactionsPage(),
    RetirementIncidentsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  void _goTo(int i) {
    setState(() => _index = i);
    // close drawer if open (mobile)
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  Widget _nav(ColorScheme cs) {
    return NavigationDrawer(
      selectedIndex: _index,
      onDestinationSelected: _goTo,
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

        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 900;

        if (isWide) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_titles[_index]),
              backgroundColor: cs.surface,
              foregroundColor: cs.onSurface,
              elevation: 0,
            ),
            body: Row(
              children: [
                SizedBox(width: 280, child: _nav(cs)),
                const VerticalDivider(width: 1),

                // centered content on web
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

        // Mobile: hamburger drawer
        return Scaffold(
          appBar: AppBar(title: Text(_titles[_index])),
          drawer: Drawer(child: SafeArea(child: _nav(cs))),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: _pages[_index],
          ),
        );
      },
    );
  }
}

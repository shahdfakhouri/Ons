import 'package:flutter/material.dart';

import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/screens/auth/login_page.dart';

import 'pages/dashboard_page.dart';
import 'pages/elders_page.dart';
import 'pages/alerts_page.dart';
import 'pages/visits_page.dart';
import 'pages/incidents_page.dart';
import 'pages/shifts_page.dart';
import 'pages/earnings_page.dart';

class CaregiverLayout extends StatefulWidget {
  final int initialIndex;
  const CaregiverLayout({super.key, this.initialIndex = 0});

  @override
  State<CaregiverLayout> createState() => _CaregiverLayoutState();
}

class _CaregiverLayoutState extends State<CaregiverLayout> {
  late int _index;

  static const _titles = [
    'Dashboard',
    'Elders',
    'Alerts',
    'Visits',
    'Incidents',
    'Shifts',
    'Earnings',
  ];

  final _pages = const [
    DashboardPage(),
    EldersPage(),
    AlertsPage(),
    VisitsPage(),
    IncidentsPage(),
    ShiftsPage(),
    EarningsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _logout(BuildContext context) {
    AuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
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
              actions: [
                TextButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (v) => setState(() => _index = v),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Elders'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.notifications_none),
                      selectedIcon: Icon(Icons.notifications),
                      label: Text('Alerts'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.event_outlined),
                      selectedIcon: Icon(Icons.event),
                      label: Text('Visits'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.report_gmailerrorred_outlined),
                      selectedIcon: Icon(Icons.report),
                      label: Text('Incidents'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.schedule_outlined),
                      selectedIcon: Icon(Icons.schedule),
                      label: Text('Shifts'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.savings_outlined),
                      selectedIcon: Icon(Icons.savings),
                      label: Text('Earnings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _pages[_index]),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[_index]),
            actions: [
              TextButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (v) => setState(() => _index = v),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                label: 'Elders',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_outlined),
                label: 'Visits',
              ),
              NavigationDestination(
                icon: Icon(Icons.report_gmailerrorred_outlined),
                label: 'Incidents',
              ),
              NavigationDestination(
                icon: Icon(Icons.schedule_outlined),
                label: 'Shifts',
              ),
              NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                label: 'Earnings',
              ),
            ],
          ),
        );
      },
    );
  }
}

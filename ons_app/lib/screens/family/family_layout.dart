import 'package:flutter/material.dart';

import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/screens/auth/login_page.dart';

import 'pages/family_dashboard_page.dart';
import 'pages/family_profile_page.dart';
import 'pages/elders/elders_list_page.dart';
import 'pages/matching/match_page.dart';
import 'pages/alerts/alerts_page.dart';
import 'pages/calendar/calendar_page.dart';
import 'pages/calls/calls_page.dart';

import 'pages/notifications/notifications_page.dart';
import 'pages/payments/family_payments_page.dart';

class FamilyLayout extends StatefulWidget {
  const FamilyLayout({super.key});

  @override
  State<FamilyLayout> createState() => _FamilyLayoutState();
}

class _FamilyLayoutState extends State<FamilyLayout> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  void _logout(BuildContext context) {
    AuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  late final List<Widget> _pages = [
    FamilyDashboardPage(onNavigate: _goTo),
    const FamilyNotificationsPage(),
    const EldersListPage(),
    const MatchPage(),
    const AlertsPage(),
    const CalendarPage(),
    const CallsPage(),
    const FamilyPaymentsPage(), // ✅ index 7
    const FamilyProfilePage(),  // ✅ index 8
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    AppBar topBar() => AppBar(
          title: const Text('Family'),
          actions: [
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
            ),
            const SizedBox(width: 8),
          ],
        );

    if (!isWide) {
      return Scaffold(
        appBar: topBar(),
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: _goTo,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dash'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Inbox'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Elders'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Match'),
            BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Payments'), // ✅ NEW
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: topBar(),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: _goTo,
            labelType: NavigationRailLabelType.all,
            minWidth: 86,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Dash'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications),
                label: Text('Inbox'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: Text('Elders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: Text('Match'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning_amber),
                label: Text('Alerts'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Calendar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.call_outlined),
                selectedIcon: Icon(Icons.call),
                label: Text('Calls'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: Text('Payments'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: IndexedStack(index: _index, children: _pages)),
        ],
      ),
    );
  }
}

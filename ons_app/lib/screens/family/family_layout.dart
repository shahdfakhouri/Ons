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
import 'package:ons_app/screens/chat_h2h/conversations_page.dart';

class FamilyLayout extends StatefulWidget {
  const FamilyLayout({super.key});

  @override
  State<FamilyLayout> createState() => _FamilyLayoutState();
}

class _FamilyLayoutState extends State<FamilyLayout> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  static const _titles = [
    'Peace of Mind', 'Inbox', 'Messages', 'My Elders', 'Smart Matching', 
    'Safety Alerts', 'Schedule', 'Voice Calls', 'Payments', 'My Profile'
  ];

  late final List<Widget> _pages = [
    FamilyDashboardPage(onNavigate: _goTo),
    const FamilyNotificationsPage(),
    const ChatH2HConversationsPage(),
    const EldersListPage(),
    const MatchPage(),
    const AlertsPage(),
    const CalendarPage(),
    const CallsPage(),
    const FamilyPaymentsPage(),
    const FamilyProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F4), // Ons Cream
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: Text(_titles[_index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            IconButton(
              onPressed: () {
                AuthService().logout();
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: isWide ? _buildWideLayout(cs) : IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: isWide ? null : _buildBottomBar(cs),
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: _goTo,
      height: 70,
      backgroundColor: Colors.white,
      indicatorColor: cs.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide, // Cleaner look for 10 items
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Dash'),
        NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Inbox'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Elders'),
        NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Match'),
        NavigationDestination(icon: Icon(Icons.warning_amber_outlined), label: 'Alerts'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
        NavigationDestination(icon: Icon(Icons.call_outlined), label: 'Calls'),
        NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Pay'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }

  Widget _buildWideLayout(ColorScheme cs) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          labelType: NavigationRailLabelType.all,
          backgroundColor: Colors.white,
          indicatorColor: cs.primaryContainer,
          destinations: _buildRailDestinations(),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: IndexedStack(index: _index, children: _pages)),
      ],
    );
  }

  List<NavigationRailDestination> _buildRailDestinations() {
    return const [
       NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
       NavigationRailDestination(icon: Icon(Icons.notifications_outlined), label: Text('Inbox')),
       NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), label: Text('Chats')),
       NavigationRailDestination(icon: Icon(Icons.groups_outlined), label: Text('Elders')),
       NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), label: Text('Match')),
       NavigationRailDestination(icon: Icon(Icons.warning_amber_outlined), label: Text('Alerts')),
       NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), label: Text('Calendar')),
       NavigationRailDestination(icon: Icon(Icons.call_outlined), label: Text('Calls')),
       NavigationRailDestination(icon: Icon(Icons.payments_outlined), label: Text('Payments')),
       NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Profile')),
    ];
  }
}
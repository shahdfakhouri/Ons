import 'package:flutter/material.dart';
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/screens/auth/login_page.dart';
import 'package:ons_app/screens/chat_h2h/conversations_page.dart';

// Your existing page imports
import 'pages/dashboard_page.dart';
import 'pages/elders_page.dart';
import 'pages/alerts_page.dart';
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
    'Care Dashboard',
    'Assigned Elders',
    'Care Alerts',
    'Messages',
    'My Shifts',
    'Revenue & Earnings',
  ];

  final _pages = const [
    DashboardPage(),
    EldersPage(),
    AlertsPage(),
    ChatH2HConversationsPage(),
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
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Text(
              _titles[_index],
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton.filledTonal(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  tooltip: 'Logout',
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
            ),
          ),
          
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (v) => setState(() => _index = v),
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: cs.surface,
                      indicatorColor: cs.primaryContainer,
                      selectedLabelTextStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelTextStyle: TextStyle(color: cs.secondary, fontSize: 12),
                      destinations: _buildRailDestinations(), // 🛠️ Fixed Type
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: _pages[_index]),
                  ],
                )
              : _pages[_index],

          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  height: 65,
                  elevation: 0,
                  backgroundColor: cs.surface,
                  indicatorColor: cs.primaryContainer,
                  selectedIndex: _index,
                  onDestinationSelected: (v) => setState(() => _index = v),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: _buildMobileDestinations(), // 🛠️ Fixed Type
                ),
        );
      },
    );
  }

  // 🏛️ HELPER 1: Correct type for NavigationRail
  List<NavigationRailDestination> _buildRailDestinations() {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: Text('Home'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_outline_rounded),
        selectedIcon: Icon(Icons.people_rounded),
        label: Text('Elders'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.notifications_none_rounded),
        selectedIcon: Icon(Icons.notifications_rounded),
        label: Text('Alerts'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: Icon(Icons.chat_bubble_rounded),
        label: Text('Chats'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.schedule_outlined),
        selectedIcon: Icon(Icons.schedule_rounded),
        label: Text('Shifts'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.savings_outlined),
        selectedIcon: Icon(Icons.savings_rounded),
        label: Text('Earnings'),
      ),
    ];
  }

  // 🏛️ HELPER 2: Correct type for NavigationBar (List<Widget>)
  List<Widget> _buildMobileDestinations() {
    return const [
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Elders'),
      NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: 'Alerts'),
      NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Chats'),
      NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule_rounded), label: 'Shifts'),
      NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings_rounded), label: 'Earnings'),
    ];
  }
}
import 'package:flutter/material.dart';
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/screens/auth/login_page.dart';

// Import Pages
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
  
  // 🎨 Your Signature Theme
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  final List<Widget> _pages = const [
    RetirementDashboardPage(), RetirementCaregiversPage(), RetirementAssignmentsPage(),
    RetirementEldersPage(), RetirementAlertsPage(), RetirementEmergenciesPage(),
    RetirementShiftsPage(), RetirementDailySummariesPage(), RetirementReportsPage(),
    RetirementPaymentsPage(), RetirementTransactionsPage(), RetirementIncidentsPage(),
    RetirementNotesPage(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  void _goTo(int i, {bool closeDrawer = false}) {
    setState(() => _index = i);
    if (closeDrawer) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isWide = c.maxWidth >= 1100;
      return Scaffold(
        backgroundColor: _cream, // Main Biophilic background
        appBar: isWide ? null : AppBar(
          title: const Text('Ons Admin'), 
          backgroundColor: _deepNavy, 
          foregroundColor: _cream,
          elevation: 0,
        ),
        drawer: isWide ? null : Drawer(child: _buildSidebar(isMobile: true)),
        body: Row(
          children: [
            if (isWide) SizedBox(width: 300, child: _buildSidebar(isMobile: false)),
            Expanded(
              child: ClipRRect(
                borderRadius: isWide ? const BorderRadius.only(topLeft: Radius.circular(40)) : BorderRadius.zero,
                child: Container(
                  color: _cream,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    appBar: isWide ? _buildTopBar() : null,
                    body: IndexedStack(index: _index, children: _pages),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        TextButton.icon(
          onPressed: () {
            AuthService().logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
          },
          icon: const Icon(Icons.logout_rounded, size: 18, color: _deepNavy),
          label: const Text("Logout", style: TextStyle(color: _deepNavy, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildSidebar({required bool isMobile}) {
    return NavigationDrawer(
      backgroundColor: Colors.white,
      indicatorColor: _sage.withOpacity(0.3), // Sage highlight for selection
      selectedIndex: _index,
      onDestinationSelected: (i) => _goTo(i, closeDrawer: isMobile),
      children: [
        _buildBrandedHeader(),
        const _SidebarLabel("MANAGEMENT"),
        _dest(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
        _dest(Icons.badge_outlined, Icons.badge_rounded, 'Caregivers'),
        _dest(Icons.link_outlined, Icons.link_rounded, 'Assignments'),
        _dest(Icons.people_outline, Icons.people_rounded, 'Residents'),
        const _SidebarLabel("OPERATIONS"),
        _dest(Icons.notifications_none, Icons.notifications_rounded, 'Alerts'),
        _dest(Icons.warning_amber_outlined, Icons.warning_rounded, 'Emergencies'),
        _dest(Icons.schedule_outlined, Icons.schedule_rounded, 'Shifts'),
        const _SidebarLabel("FINANCE & DATA"),
        _dest(Icons.insights_outlined, Icons.insights_rounded, 'Reports'),
        _dest(Icons.payments_outlined, Icons.payments_rounded, 'Payments'),
        _dest(Icons.report_gmailerrorred_outlined, Icons.report_rounded, 'Incidents'),
        const SizedBox(height: 20),
      ],
    );
  }

  NavigationDrawerDestination _dest(IconData icon, IconData selected, String label) {
    return NavigationDrawerDestination(
      icon: Icon(icon, size: 20, color: _denim),
      selectedIcon: Icon(selected, size: 20, color: _deepNavy),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _deepNavy)),
    );
  }

  Widget _buildBrandedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _deepNavy, 
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.2), blurRadius: 10)]
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: _cream, size: 22),
          ),
          const SizedBox(height: 20),
          const Text('Ons', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _deepNavy, letterSpacing: -1)),
          const Text('RETIREMENT HOME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _denim, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  final String text;
  const _SidebarLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 10),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF8E9297))),
    );
  }
}
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
import 'pages/payments_page.dart'; 
import 'pages/incidents_page.dart';

class RetirementHomeLayout extends StatefulWidget {
  final int initialIndex;
  const RetirementHomeLayout({super.key, this.initialIndex = 0});

  @override
  State<RetirementHomeLayout> createState() => _RetirementHomeLayoutState();
}

class _RetirementHomeLayoutState extends State<RetirementHomeLayout> {
  late int _index;
  
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  final List<Widget> _pages = const [
    RetirementDashboardPage(),
    RetirementCaregiversPage(),
    RetirementAssignmentsPage(),
    RetirementEldersPage(),
    RetirementAlertsPage(),
    RetirementEmergenciesPage(),
    RetirementShiftsPage(),
    RetirementPaymentsPage(),
    RetirementIncidentsPage(),
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

  void _handleLogout() {
    AuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // Logic for Web vs Mobile
      final bool isWide = c.maxWidth >= 1100;

      return Scaffold(
        backgroundColor: _cream,
        // Mobile AppBar
        appBar: isWide ? null : AppBar(
          title: const Text('Ons Retirement', style: TextStyle(fontWeight: FontWeight.bold)), 
          backgroundColor: _cream, 
          foregroundColor: _deepNavy,
          elevation: 0,
          centerTitle: true,
        ),
        // Mobile Sidebar (Drawer)
        drawer: isWide ? null : Drawer(
          backgroundColor: Colors.white,
          child: _buildSidebar(isMobile: true)
        ),
        body: Row(
          children: [
            // Desktop Sidebar
            if (isWide) SizedBox(width: 280, child: _buildSidebar(isMobile: false)),
            
            // Main Content Area
            Expanded(
              child: Container(
                color: _cream,
                child: Column(
                  children: [
                    // Desktop TopBar (contains logout)
                    if (isWide) _buildDesktopTopBar(),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: isWide 
                            ? const BorderRadius.only(topLeft: Radius.circular(32)) 
                            : BorderRadius.zero,
                        child: Container(
                          color: Colors.white.withOpacity(0.5),
                          child: IndexedStack(index: _index, children: _pages),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDesktopTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, size: 18, color: _deepNavy),
            label: const Text("Logout", style: TextStyle(color: _deepNavy, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isMobile}) {
    return Column(
      children: [
        Expanded(
          child: NavigationDrawer(
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: _sage.withOpacity(0.2),
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
              _dest(Icons.payments_outlined, Icons.payments_rounded, 'Payments'),
              _dest(Icons.report_gmailerrorred_outlined, Icons.report_rounded, 'Incidents'),
            ],
          ),
        ),
        // FIXED LOGOUT BUTTON: Appears at the bottom of the sidebar for Mobile
        if (isMobile) 
          Padding(
            padding: const EdgeInsets.all(20),
            child: ListTile(
              onTap: _handleLogout,
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.redAccent.withOpacity(0.05),
            ),
          ),
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
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF8E9297))),
    );
  }
}
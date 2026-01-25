import 'package:flutter/material.dart';

import 'pages/elder_home_page.dart';
import 'pages/medication_today_page.dart';
import 'pages/mood_page.dart';
import 'pages/symptoms_page.dart';
import 'pages/emergency_page.dart';
import 'pages/calls_page.dart';
import 'pages/location_page.dart';
import 'pages/gallery_page.dart';
import 'pages/entertainment/elder_entertainment_page.dart';
import 'pages/notifications_page.dart';
import 'pages/consent_page.dart';
import 'pages/profile_page.dart';
import 'pages/community/elder_community_feed_page.dart';
import 'pages/companion/elder_companion_chat_page.dart';

class ElderLayout extends StatefulWidget {
  const ElderLayout({super.key});

  @override
  State<ElderLayout> createState() => _ElderLayoutState();
}

class _ElderLayoutState extends State<ElderLayout> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ✅ Every widget now receives 'nav' (the _goTo function) as its 'onBack' or 'onNavigate' callback
  late final List<Map<String, dynamic>> _navItems = [
    {'label': 'Home', 'icon': Icons.home, 'widget': (nav) => ElderHomePage(onNavigate: nav)},                 // 0
    {'label': 'Meds', 'icon': Icons.medication, 'widget': (nav) => MedicationTodayPage(onBack: nav)},          // 1
    {'label': 'Mood', 'icon': Icons.mood, 'widget': (nav) => MoodPage(onBack: nav)},                         // 2
    {'label': 'Symptoms', 'icon': Icons.healing, 'widget': (nav) => SymptomsPage(onBack: nav)},               // 3
    {'label': 'SOS', 'icon': Icons.sos, 'widget': (nav) => EmergencyPage(onBack: nav)},                    // 4
    {'label': 'Calls', 'icon': Icons.call, 'widget': (nav) => CallsPage(onBack: nav)},                      // 5
    {'label': 'Location', 'icon': Icons.location_on, 'widget': (nav) => LocationPage(onBack: nav)},           // 6
    {'label': 'Gallery', 'icon': Icons.photo, 'widget': (nav) => GalleryPage(onBack: nav)},                 // 7
    {'label': 'Fun', 'icon': Icons.play_circle, 'widget': (nav) => ElderEntertainmentPage(onBack: nav)},      // 8
    {'label': 'Inbox', 'icon': Icons.notifications, 'widget': (nav) => NotificationsPage(onBack: nav)},       // 9
    {'label': 'Privacy', 'icon': Icons.lock, 'widget': (nav) => ConsentPage(onBack: nav)},                  // 10
    {'label': 'Profile', 'icon': Icons.person, 'widget': (nav) => ProfilePage(onBack: nav)},                // 11
    {'label': 'Community', 'icon': Icons.forum, 'widget': (nav) => ElderCommunityFeedPage(onBack: nav)},     // 12
    {'label': 'Companion', 'icon': Icons.smart_toy, 'widget': (nav) => ElderCompanionChatPage(onBack: nav)}, // 13
  ];

  void _goTo(int i) {
    if (i < 0 || i >= _navItems.length) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 900;

    if (!isWide) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Prevents website home redirect
          title: Text(_navItems[_index]['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            if (_index != 4) 
              IconButton(
                icon: const Icon(Icons.sos, color: Colors.red),
                onPressed: () => _goTo(4),
              ),
          ],
        ),
        drawer: _buildElderDrawer(),
        body: _navItems[_index]['widget'](_goTo),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index <= 3 ? _index : 4, 
          onTap: (i) {
            if (i == 4) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              _goTo(i);
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF313647),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Meds'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
            BottomNavigationBarItem(icon: Icon(Icons.sos, color: Colors.red), label: 'SOS'),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isWide,
            selectedIndex: _index,
            onDestinationSelected: _goTo,
            leading: _buildRailHeader(isWide),
            destinations: _navItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item['icon']),
                label: Text(item['label']),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _navItems[_index]['widget'](_goTo)),
        ],
      ),
    );
  }

  Widget _buildElderDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF313647)),
            child: Center(
              child: Text('Ons Menu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, i) {
                return ListTile(
                  leading: Icon(_navItems[i]['icon'], color: _index == i ? const Color(0xFFA3B087) : null),
                  title: Text(_navItems[i]['label'], style: TextStyle(fontWeight: _index == i ? FontWeight.bold : FontWeight.normal)),
                  onTap: () {
                    _goTo(i);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailHeader(bool extended) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: extended 
        ? const Text("ONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF313647))) 
        : const Icon(Icons.auto_awesome, color: Color(0xFF313647)),
    );
  }
}
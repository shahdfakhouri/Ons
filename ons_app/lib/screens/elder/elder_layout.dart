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

  void _goTo(int i) {
    if (i < 0 || i >= _pages.length) return; // ✅ guard
    setState(() => _index = i);
  }

  late final List<Widget> _pages = [
    ElderHomePage(onNavigate: _goTo), // 0
    const MedicationTodayPage(),      // 1
    const MoodPage(),                 // 2
    const SymptomsPage(),             // 3
    const EmergencyPage(),            // 4
    const CallsPage(),                // 5
    const LocationPage(),             // 6
    const GalleryPage(),              // 7
    const ElderEntertainmentPage(),
      // 10
    const ProfilePage(),              // 11
    const ElderCommunityFeedPage(),   // 12
    const ElderCompanionChatPage(),   // 13
  ];

  int get _safeIndex {
    final max = _pages.length - 1;
    if (_index < 0) return 0;
    if (_index > max) return max;
    return _index;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (!isWide) {
      return Scaffold(
        body: IndexedStack(index: _safeIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _safeIndex,
          onTap: _goTo,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),            // 0
            BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Meds'),      // 1
            BottomNavigationBarItem(icon: Icon(Icons.mood), label: 'Mood'),            // 2
            BottomNavigationBarItem(icon: Icon(Icons.healing), label: 'Symptoms'),     // 3
            BottomNavigationBarItem(icon: Icon(Icons.sos), label: 'SOS'),              // 4
            BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),           // 5
            BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Location'), // 6
            BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Gallery'),        // 7
            BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Fun'),      // 8
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Inbox'),  // 9
            BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Privacy'),         // 10
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),       // 11
            BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Community'),      // 12
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'Companion'),  // ✅ 13
          ],
        ),
      );
    }

    // ✅ Wide layout
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 92,
            child: NavigationRail(
              selectedIndex: _safeIndex, // ✅ safe
              onDestinationSelected: _goTo,
              groupAlignment: -1,
              labelType: NavigationRailLabelType.none,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.medication_outlined),
                  selectedIcon: Icon(Icons.medication),
                  label: Text('Meds'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.mood_outlined),
                  selectedIcon: Icon(Icons.mood),
                  label: Text('Mood'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.healing_outlined),
                  selectedIcon: Icon(Icons.healing),
                  label: Text('Symptoms'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sos_outlined),
                  selectedIcon: Icon(Icons.sos),
                  label: Text('SOS'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.call_outlined),
                  selectedIcon: Icon(Icons.call),
                  label: Text('Calls'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.location_on_outlined),
                  selectedIcon: Icon(Icons.location_on),
                  label: Text('Location'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.photo_outlined),
                  selectedIcon: Icon(Icons.photo),
                  label: Text('Gallery'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.play_circle_outline),
                  selectedIcon: Icon(Icons.play_circle),
                  label: Text('Fun'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: Text('Inbox'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.lock_outline),
                  selectedIcon: Icon(Icons.lock),
                  label: Text('Privacy'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum),
                  label: Text('Community'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  selectedIcon: Icon(Icons.smart_toy),
                  label: Text('Companion'),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: IndexedStack(index: _safeIndex, children: _pages)),
        ],
      ),
    );
  }
}

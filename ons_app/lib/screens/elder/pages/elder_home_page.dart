import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/widgets/big_button.dart';

class ElderHomePage extends StatelessWidget {
  final void Function(int index) onNavigate;
  const ElderHomePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          BigButton(
            icon: Icons.medication,
            title: 'Medicines',
            subtitle: 'Today schedule + confirm',
            onTap: () => onNavigate(1),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.mood,
            title: 'Mood',
            subtitle: 'How are you feeling?',
            onTap: () => onNavigate(2),
          ),
          const SizedBox(height: 10),

          // ✅ AI Companion (index 13)
          BigButton(
            icon: Icons.smart_toy,
            title: 'AI Companion',
            subtitle: 'Talk and feel better',
            onTap: () => onNavigate(13),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.healing,
            title: 'Symptoms',
            subtitle: 'Report symptoms quickly',
            onTap: () => onNavigate(3),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.sos,
            title: 'Emergency',
            subtitle: 'Big SOS button',
            danger: true,
            onTap: () => onNavigate(4),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.call,
            title: 'Calls',
            subtitle: 'Request call + history',
            onTap: () => onNavigate(5),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.location_on,
            title: 'Location',
            subtitle: 'Where am I + safe zones',
            onTap: () => onNavigate(6),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.photo,
            title: 'Gallery',
            subtitle: 'View + upload',
            onTap: () => onNavigate(7),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.play_circle,
            title: 'Entertainment',
            subtitle: 'Simple content feed',
            onTap: () => onNavigate(8),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.notifications,
            title: 'Inbox',
            subtitle: 'Notifications',
            onTap: () => onNavigate(9),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.lock,
            title: 'Privacy',
            subtitle: 'Who can see what?',
            onTap: () => onNavigate(10),
          ),
          const SizedBox(height: 10),

          BigButton(
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'Font, language, voice',
            onTap: () => onNavigate(11),
          ),
          const SizedBox(height: 10),

          // ✅ Community (index 12)
          BigButton(
            icon: Icons.forum,
            title: 'Community',
            subtitle: 'Posts + comments',
            onTap: () => onNavigate(12),
          ),
        ],
      ),
    );
  }
}

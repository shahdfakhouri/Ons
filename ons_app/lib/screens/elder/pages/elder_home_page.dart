import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/widgets/big_button.dart';

class ElderHomePage extends StatelessWidget {
  final void Function(int index) onNavigate;
  const ElderHomePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    // Breakpoints for better scaling
    final double width = MediaQuery.sizeOf(context).width;
    final bool isMobile = width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4), // ONS Signature Cream
   appBar: AppBar(
  automaticallyImplyLeading: false, // This removes the back button
  title: const Text('Good Morning', style: TextStyle(fontWeight: FontWeight.bold)),
  backgroundColor: Colors.transparent,
  elevation: 0,
  centerTitle: false,
),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How can we help you today?",
              style: TextStyle(fontSize: 18, color: Color(0xFF435663)),
            ),
            const SizedBox(height: 24),

            // Priority Section: Critical Health & Safety
            _buildSectionLabel("Safety & Health"),
            const SizedBox(height: 12),
            BigButton(
              icon: Icons.sos,
              title: 'Emergency',
              subtitle: 'Press for immediate help',
              danger: true,
              onTap: () => onNavigate(4),
            ),
            const SizedBox(height: 12),
            
            // Grid Layout for main features to reduce vertical scrolling
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isMobile ? 2.8 : 2.2,
                  children: [
                    BigButton(
                      icon: Icons.medication,
                      title: 'Medicines',
                      subtitle: 'View your schedule',
                      onTap: () => onNavigate(1),
                    ),
                    BigButton(
                      icon: Icons.smart_toy,
                      title: 'AI Companion',
                      subtitle: 'Talk and feel better',
                      onTap: () => onNavigate(13),
                    ),
                    BigButton(
                      icon: Icons.forum,
                      title: 'Community',
                      subtitle: 'Connect with others',
                      onTap: () => onNavigate(12),
                    ),
                    BigButton(
                      icon: Icons.mood,
                      title: 'Mood',
                      subtitle: 'Check-in today',
                      onTap: () => onNavigate(2),
                    ),
                    BigButton(
                      icon: Icons.healing,
                      title: 'Symptoms',
                      subtitle: 'Report a feeling',
                      onTap: () => onNavigate(3),
                    ),
                    BigButton(
                      icon: Icons.location_on,
                      title: 'Location',
                      subtitle: 'Where am I?',
                      onTap: () => onNavigate(6),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            _buildSectionLabel("Connect & Fun"),
            const SizedBox(height: 12),

            // Secondary features
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                BigButton(
                  icon: Icons.call,
                  title: 'Calls',
                  subtitle: 'Speak with family',
                  onTap: () => onNavigate(5),
                ),
                const SizedBox(height: 12),
                BigButton(
                  icon: Icons.play_circle,
                  title: 'Entertainment',
                  subtitle: 'Fun and games',
                  onTap: () => onNavigate(8),
                ),
                const SizedBox(height: 12),
                BigButton(
                  icon: Icons.photo,
                  title: 'Gallery',
                  subtitle: 'View photos',
                  onTap: () => onNavigate(7),
                ),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionLabel("Settings"),
            const SizedBox(height: 12),
            
            // Administrative items
            Row(
              children: [
                Expanded(
                  child: BigButton(
                    icon: Icons.notifications,
                    title: 'Inbox',
                    subtitle: 'Alerts',
                    onTap: () => onNavigate(9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BigButton(
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: 'Settings',
                    onTap: () => onNavigate(11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8E9297),
        letterSpacing: 1.2,
      ),
    );
  }
}
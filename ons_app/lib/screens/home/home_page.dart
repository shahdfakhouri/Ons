import 'package:flutter/material.dart';

import 'package:ons_app/screens/home/sections/header.dart';
import 'package:ons_app/screens/home/sections/hero.dart';
import 'package:ons_app/screens/home/sections/features.dart';
import 'package:ons_app/screens/elder/elder_mode_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      body: Stack(
        children: [
          // Scrollable content (Hero + Features + more)
          SingleChildScrollView(
            child: Column(
              children: const [
                SizedBox(height: 120), // space for transparent header
                HeroSection(),
                FeaturesSection(),
              ],
            ),
          ),

          // Floating transparent header
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderSection(),
          ),
        ],
      ),

      // 🔹 TEMP button just to test Elder Mode from PC
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ElderModePage(
                elderName: 'أم أحمد',
                nextVisitText: 'اليوم الساعة ٤:٠٠ مساءً - زيارة سارة (الممرضة)',
              ),
            ),
          );
        },
        icon: const Icon(Icons.elderly),
        label: const Text('وضع المسن'),
      ),
    );
  }
}

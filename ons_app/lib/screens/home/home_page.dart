import 'package:flutter/material.dart';

import 'package:ons_app/screens/home/sections/header.dart';
import 'package:ons_app/screens/home/sections/hero.dart';
import 'package:ons_app/screens/home/sections/features.dart';

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
    );
  }
}

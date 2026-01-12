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
          SingleChildScrollView(
            child: Column(
              children: const [
                SizedBox(height: 120),
                HeroSection(),
                FeaturesSection(),
                SizedBox(height: 80),
              ],
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderSection(),
          ),
        ],
      ),

      // ✅ Elder Mode entry
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/elder/login');
        },
        icon: const Icon(Icons.elderly),
        label: const Text('Elder Mode'),
      ),
    );
  }
}

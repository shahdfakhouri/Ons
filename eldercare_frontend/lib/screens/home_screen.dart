import 'package:flutter/material.dart';
import '../widgets/navbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: const [
            Navbar(),
            HeroSection(),
          ],
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    // For responsiveness: stack column on small screens, row on big ones
    final isWide = MediaQuery.of(context).size.width > 700;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Flex(
        direction: isWide ? Axis.horizontal : Axis.vertical,
        children: [
          // LEFT SIDE (Text & Button)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: BorderRadius.circular(32),
              ),
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ons Eldercare+',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'IMPACTING YOU\nFOR A BETTER LIFE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'WATCH OUR STORY',
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20, height: 20),

          // RIGHT SIDE (Image)
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
  'assets/images/First.jpg',
  fit: BoxFit.cover,
  height: 400,
),

            ),
          ),
        ],
      ),
    );
  }
}

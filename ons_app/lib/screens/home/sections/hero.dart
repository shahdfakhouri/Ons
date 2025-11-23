import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ons_app/core/theme/app_theme.dart';


class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        // Background Image
        SizedBox(          width: double.infinity,
          height: 520,
          child: Image.asset(
            'assets/hero.jpg',
            fit: BoxFit.cover,
          ),
        ),

        // Dark overlay to improve text readability
        Container(
          height: 520,
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.35),
        ),

        // Text + Call To Action
        SizedBox(
          height: 520,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Because Everyone Deserves Care and Connection",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Ons makes supporting your loved ones easier than ever.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 30),

               ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.denim,  
              foregroundColor: AppTheme.cream,   
              padding: const EdgeInsets.symmetric(
              horizontal: 34,
              vertical: 14,
              ),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              ),
            elevation: 3,
  ),
  child: Text(
    "Get Started",
    style: GoogleFonts.playfairDisplay(
      fontSize: 19,
    ),
  ),
),

              ],
            ),
          ),
        ),
      ],
    );
  }
}

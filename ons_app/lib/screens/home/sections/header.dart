import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ons_app/screens/auth/login_page.dart'; 
import 'package:ons_app/screens/auth/register_page.dart';


class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      color: const Color(0xFFFFF8D4), // your light beige
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LOGO
          Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 65,
              ),
              const SizedBox(width: 10),
              // you can add a title later if you want
            ],
          ),

          // BUTTONS
          Row(
            children: [
              TextButton(
                onPressed: () {
                  // 👉 Go to LoginPage
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                  );
                },
                child: Text(
                  "Login",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    color: const Color(0xFF435663), // deep bluish
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF435663).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () {
                     Navigator.of(context).push(
                       MaterialPageRoute(
                         builder: (_) => const RegisterPage(),
                       ),
                     );
                  },
                  child: Text(
                    "Sign Up",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

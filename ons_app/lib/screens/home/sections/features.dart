import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ons_app/core/theme/app_theme.dart';



class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // REAL ONS FEATURES (7 total)
    final List<Map<String, dynamic>> features = [
      {
        "title": "Dashboard",
        "description": "All care information in one simple view.",
        "icon": Icons.dashboard,
      },
      {
        "title": "Health Tracking",
        "description": "Vitals, mood updates, and daily wellbeing.",
        "icon": Icons.favorite,
      },
      {
        "title": "Instant Alerts",
        "description": "Immediate notifications when help is needed.",
        "icon": Icons.notifications_active,
      },
      {
        "title": "AI Companion",
        "description": "Smart voice assistant for comfort and support.",
        "icon": Icons.smart_toy,
      },
      {
        "title": "Entertainment",
        "description": "Music, stories, and cognitive games.",
        "icon": Icons.headset,
      },
      {
        "title": "Caregiver Matching",
        "description": "Choose freelance or retirement home caregivers.",
        "icon": Icons.group,
      },
      {
        "title": "Family Monitoring",
        "description": "Daily logs, vitals, and caregiver notes.",
        "icon": Icons.visibility,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Our Features",
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepNavy,
            ),
          ),

          const SizedBox(height: 50),

          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 700;

              if (isMobile) {
                // ************** MOBILE LAYOUT (COLUMN) **************
                return Column(
                  children: [
                    for (var f in features) ...[
                      FeatureCard(
                        title: f["title"],
                        description: f["description"],
                        icon: f["icon"],
                      ),
                      const SizedBox(height: 20),
                    ]
                  ],
                );
              }

              // ************** DESKTOP LAYOUT (GRID 3x3) **************
              return Wrap(
                spacing: 30,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: [
                  for (var f in features)
                    FeatureCard(
                      title: f["title"],
                      description: f["description"],
                      icon: f["icon"],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,

        transform: _isHovered
            ? (Matrix4.identity()..scale(1.05))
            : (Matrix4.identity()),

        padding: const EdgeInsets.all(24),
        width: 260,
        height: 240,
        decoration: BoxDecoration(
          color: colors.surface, // from theme
          borderRadius: BorderRadius.circular(16),

          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  )
                ]
              : [
                  BoxShadow(
                    color: colors.onSurface.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  )
                ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 38,
              color: _isHovered ? AppTheme.deepNavy : AppTheme.sage,
            ),

            const SizedBox(height: 18),

            Text(
              widget.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepNavy,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 14,
               
                // ignore: deprecated_member_use
                color: AppTheme.deepNavy.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

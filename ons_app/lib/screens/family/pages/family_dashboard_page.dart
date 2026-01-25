import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class FamilyDashboardPage extends StatefulWidget {
  final void Function(int index) onNavigate;
  const FamilyDashboardPage({super.key, required this.onNavigate});

  @override
  State<FamilyDashboardPage> createState() => _FamilyDashboardPageState();
}

class _FamilyDashboardPageState extends State<FamilyDashboardPage> {
  final api = FamilyApi();

  // 🎨 Signature Theme Palette (Unified)
  static const _deepNavy = Color(0xFF313647);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4); // Matches Profile

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream, // ✅ Now matches profile
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: _deepNavy,
        child: FutureBuilder(
          future: api.getDashboard(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _deepNavy));
            
            final data = snap.data as Map<String, dynamic>;
            final msg = data['msg'] ?? 'Welcome Back';

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                // 🟢 SIGNATURE HERO CARD
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _deepNavy,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: _deepNavy.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white10, 
                        child: Icon(Icons.favorite_rounded, color: _sage, size: 20)
                      ),
                      const SizedBox(height: 24),
                      Text(msg, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      const Text("Everything is on track with your loved ones today.", 
                        style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                const SectionTitle('Quick Management'),
                const SizedBox(height: 16),
                
                // 🛠️ GRID ACTIONS (Optimized for Bento Style)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _QuickActionCard(icon: Icons.groups_rounded, label: 'Elders', color: Colors.indigo, onTap: () => widget.onNavigate(3)),
                    _QuickActionCard(icon: Icons.chat_bubble_rounded, label: 'Messages', color: Colors.blue, onTap: () => widget.onNavigate(2)),
                    _QuickActionCard(icon: Icons.warning_amber_rounded, label: 'Alerts', color: Colors.redAccent, onTap: () => widget.onNavigate(5)),
                    _QuickActionCard(icon: Icons.payments_rounded, label: 'Payments', color: Colors.green, onTap: () => widget.onNavigate(8)),
                    _QuickActionCard(icon: Icons.calendar_month_rounded, label: 'Schedule', color: Colors.orange, onTap: () => widget.onNavigate(6)),
                    _QuickActionCard(icon: Icons.person_rounded, label: 'Profile', color: Colors.blueGrey, onTap: () => widget.onNavigate(9)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: const Color(0xFF313647).withOpacity(0.03), blurRadius: 15)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF313647))),
          ],
        ),
      ),
    );
  }
}
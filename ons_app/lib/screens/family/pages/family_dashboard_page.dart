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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder(
          future: api.getDashboard(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            
            final data = snap.data as Map<String, dynamic>;
            final msg = data['msg'] ?? 'Welcome Back';

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 🟢 HERO WELCOME CARD
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.favorite, color: Colors.white)),
                      const SizedBox(height: 20),
                      Text(msg, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("Everything is on track with your loved ones today.", 
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const SectionTitle('Quick Management'),
                const SizedBox(height: 16),
                
                // 🛠️ GRID ACTIONS
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _QuickActionCard(icon: Icons.groups, label: 'Elders', color: Colors.indigo, onTap: () => widget.onNavigate(3)),
                    _QuickActionCard(icon: Icons.chat_bubble, label: 'Messages', color: Colors.blue, onTap: () => widget.onNavigate(2)),
                    _QuickActionCard(icon: Icons.warning_amber_rounded, label: 'Alerts', color: Colors.redAccent, onTap: () => widget.onNavigate(5)),
                    _QuickActionCard(icon: Icons.payments, label: 'Payments', color: Colors.green, onTap: () => widget.onNavigate(8)),
                    _QuickActionCard(icon: Icons.calendar_month, label: 'Schedule', color: Colors.orange, onTap: () => widget.onNavigate(6)),
                    _QuickActionCard(icon: Icons.person, label: 'Profile', color: Colors.blueGrey, onTap: () => widget.onNavigate(9)),
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
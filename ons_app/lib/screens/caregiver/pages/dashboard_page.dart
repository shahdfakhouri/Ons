import 'package:flutter/material.dart';
import 'package:ons_app/services/caregiver_api.dart';
import 'package:ons_app/services/payment_api.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _caregiverApi = CaregiverApi();
  final _paymentApi = PaymentApi();
  
  bool _loading = true;
  String? _error;
  
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _activeShift; 
  double _totalRevenue = 0.0;
  int _totalCompletedShifts = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ✅ Using exact method names from your CaregiverApi class
      final results = await Future.wait([
        _caregiverApi.getMyProfile(),
        _paymentApi.getReceiverRevenue(),
        _caregiverApi.getMyShiftHistory(limit: 100), // Updated endpoint name
        _caregiverApi.getMyActiveShift(),           // Updated endpoint name
      ]);
      
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          
          // 💰 Handle Revenue
          final revRes = results[1] as Map<String, dynamic>;
          _totalRevenue = double.tryParse(revRes['receiver_revenue']?.toString() ?? '0.0') ?? 0.0;
          
          // 🕒 Handle Shift History (Count only completed ones)
          final historyList = results[2] as List<dynamic>;
          _totalCompletedShifts = historyList.where((s) => s['shift_end'] != null).length;
          
          // 🟢 Handle Current Active Shift
          _activeShift = results[3] as Map<String, dynamic>?; 
          
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _goTab(int index) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CaregiverLayout(initialIndex: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorState(cs, tt);

    final name = (_profile?['name'] ?? 'Caregiver').toString();
    final bool isOnShift = _activeShift != null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeroHeader(name, isOnShift, cs, tt),
          const SizedBox(height: 24),

          _buildMetricsRow(cs, tt),
          const SizedBox(height: 24),

          Text('Navigation Hub', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _NavTile(icon: Icons.people_alt_rounded, label: 'Elders', color: Colors.indigo, onTap: () => _goTab(1)),
              _NavTile(icon: Icons.chat_bubble_rounded, label: 'Messages', color: Colors.blue, onTap: () => _goTab(3)),
              _NavTile(icon: Icons.notifications_active_rounded, label: 'Alerts', color: Colors.redAccent, onTap: () => _goTab(2)),
              _NavTile(icon: Icons.payments_rounded, label: 'Earnings', color: Colors.green, onTap: () => _goTab(5)),
            ],
          ),
          const SizedBox(height: 16),
          
          _FullWidthAction(
            icon: Icons.history_rounded,
            label: "View All Shift History",
            onTap: () => _goTab(4),
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(String name, bool isOnShift, ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: cs.onPrimary.withOpacity(0.2),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', 
                  style: TextStyle(color: cs.onPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              _StatusPill(isOnShift: isOnShift),
            ],
          ),
          const SizedBox(height: 20),
          Text('Welcome back,', style: TextStyle(color: cs.onPrimary.withOpacity(0.7), fontSize: 16)),
          Text(name, style: TextStyle(color: cs.onPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
          if (isOnShift) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "Active at: ${_activeShift!['home_name'] ?? 'Assigned Home'}", 
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMetricsRow(ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        _MetricCard(
          label: "Total Completed", 
          value: "$_totalCompletedShifts Shifts", 
          icon: Icons.task_alt_rounded, 
          color: cs.primary
        ),
        const SizedBox(width: 12),
        _MetricCard(
          label: "Total Earnings", 
          value: "\$${_totalRevenue.toStringAsFixed(2)}", 
          icon: Icons.account_balance_wallet, 
          color: Colors.green
        ),
      ],
    );
  }

  Widget _buildErrorState(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync_problem_rounded, size: 64, color: cs.error),
          const SizedBox(height: 16),
          const Text("Dashboard sync failed."),
          TextButton(onPressed: _load, child: const Text("Retry Connection")),
        ],
      ),
    );
  }
}

// --- Supporting UI Components ---

class _StatusPill extends StatelessWidget {
  final bool isOnShift;
  const _StatusPill({required this.isOnShift});
  @override
  Widget build(BuildContext context) {
    final color = isOnShift ? Colors.greenAccent : Colors.white.withOpacity(0.2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        isOnShift ? "ON SHIFT" : "OFF DUTY", 
        style: TextStyle(
          color: isOnShift ? Colors.black87 : Colors.white, 
          fontSize: 10, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1
        )
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }
}

class _FullWidthAction extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final ColorScheme cs;
  const _FullWidthAction({required this.icon, required this.label, required this.onTap, required this.cs});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: cs.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(icon, color: cs.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
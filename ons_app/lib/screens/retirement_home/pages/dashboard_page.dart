import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementDashboardPage extends StatefulWidget {
  const RetirementDashboardPage({super.key});
  @override
  State<RetirementDashboardPage> createState() => _RetirementDashboardPageState();
}

class _RetirementDashboardPageState extends State<RetirementDashboardPage> {
  final _api = RetirementHomeApi();
  final _formKey = GlobalKey<FormState>();
  
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _cream = Color(0xFFFFF8D4);
  static const _sage = Color(0xFFA3B087);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  final _name = TextEditingController();
  final _monthly = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _monthly.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final j = await _api.getDashboard();
      setState(() {
        _stats = j['stats'] ?? j['overview'];
        _name.text = (j['homeInfo']?['name'] ?? '').toString();
        _monthly.text = (j['homeInfo']?['monthly_cost'] ?? '').toString();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = "System Sync Error: $e"; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _deepNavy));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    return RefreshIndicator(
      onRefresh: _load,
      color: _deepNavy,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Text("Morning, Admin", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _deepNavy, letterSpacing: -1)),
          const Text("The facility is currently running at peak efficiency.", style: TextStyle(color: _denim, fontSize: 16)),
          const SizedBox(height: 36),
          _buildBentoGrid(),
          const SizedBox(height: 48),
          _buildElevatedProfileCard(),
        ],
      ),
    );
  }

  Widget _buildBentoGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.4,
        // ✅ No 'const' keywords here because _stats is a variable
        children: [
          _bentoItem("Residents", _stats?['totalElders'], Icons.elderly_rounded, _sage),
          _bentoItem("Staff", _stats?['totalCaregivers'], Icons.badge_rounded, _denim),
          _bentoItem("Active Alerts", _stats?['totalAlerts'], Icons.warning_amber_rounded, Colors.redAccent),
          _bentoItem("Status", "Live", Icons.wifi_tethering_rounded, _deepNavy),
        ],
      );
    });
  }

  Widget _bentoItem(String label, dynamic val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(val?.toString() ?? '-', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _deepNavy)),
              Text(label, style: const TextStyle(color: _denim, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElevatedProfileCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.05), blurRadius: 40)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Facility Configuration", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _deepNavy)),
            const SizedBox(height: 32),
            _styledInput(_name, "Facility Name", Icons.business_rounded),
            _styledInput(_monthly, "Monthly Rate (\$)", Icons.monetization_on_rounded),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton(
                onPressed: () {}, // Implementation of _saveProfile
                style: FilledButton.styleFrom(
                  backgroundColor: _deepNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Sync Profile Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _cream)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _styledInput(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _denim, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: _deepNavy, size: 22),
          filled: true,
          fillColor: _cream.withOpacity(0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        ),
      ),
    );
  }
}
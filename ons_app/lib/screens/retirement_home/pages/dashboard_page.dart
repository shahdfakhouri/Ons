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

    // Detect if we are on a small screen
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: _load,
      color: _deepNavy,
      child: ListView(
        // Responsive padding: less on mobile, more on web
        padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
        children: [
          Text(
            "Morning, Admin", 
            style: TextStyle(
              fontSize: isSmallScreen ? 28 : 34, 
              fontWeight: FontWeight.w900, 
              color: _deepNavy, 
              letterSpacing: -1
            )
          ),
          Text(
            "The facility is currently running at peak efficiency.", 
            style: TextStyle(color: _denim, fontSize: isSmallScreen ? 14 : 16)
          ),
          const SizedBox(height: 36),
          _buildBentoGrid(isSmallScreen),
          const SizedBox(height: 32),
          _buildElevatedProfileCard(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(bool isSmallScreen) {
    return LayoutBuilder(builder: (context, constraints) {
      // 1 column for very small phones, 2 for tablets, 4 for web
      int crossAxisCount = constraints.maxWidth < 450 ? 1 : (constraints.maxWidth > 900 ? 4 : 2);
      
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        // Wider aspect ratio on mobile so items aren't too tall
        childAspectRatio: isSmallScreen ? 2.0 : 1.4,
        children: [
          _bentoItem("Residents", _stats?['totalElders'], Icons.elderly_rounded, _sage, isSmallScreen),
          _bentoItem("Staff", _stats?['totalCaregivers'], Icons.badge_rounded, _denim, isSmallScreen),
          _bentoItem("Active Alerts", _stats?['totalAlerts'], Icons.warning_amber_rounded, Colors.redAccent, isSmallScreen),
          _bentoItem("Status", "Live", Icons.wifi_tethering_rounded, _deepNavy, isSmallScreen),
        ],
      );
    });
  }

  Widget _bentoItem(String label, dynamic val, IconData icon, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: isSmallScreen ? 18 : 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                val?.toString() ?? '-', 
                style: TextStyle(fontSize: isSmallScreen ? 24 : 30, fontWeight: FontWeight.w900, color: _deepNavy)
              ),
              Text(
                label, 
                style: const TextStyle(color: _denim, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElevatedProfileCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 40),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.05), blurRadius: 40)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Facility Configuration", 
              style: TextStyle(fontSize: isSmallScreen ? 18 : 22, fontWeight: FontWeight.w900, color: _deepNavy)
            ),
            const SizedBox(height: 24),
            _styledInput(_name, "Facility Name", Icons.business_rounded),
            _styledInput(_monthly, "Monthly Rate (\$)", Icons.monetization_on_rounded),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {}, 
                style: FilledButton.styleFrom(
                  backgroundColor: _deepNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Sync Profile Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _cream)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _styledInput(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _denim, fontWeight: FontWeight.w600, fontSize: 14),
          prefixIcon: Icon(icon, color: _deepNavy, size: 20),
          filled: true,
          fillColor: _cream.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}
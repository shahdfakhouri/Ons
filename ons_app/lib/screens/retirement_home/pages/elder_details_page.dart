import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'package:ons_app/services/retirement_medication_api.dart';

class RetirementElderDetailsPage extends StatefulWidget {
  final int elderId;
  const RetirementElderDetailsPage({super.key, required this.elderId});

  @override
  State<RetirementElderDetailsPage> createState() => _RetirementElderDetailsPageState();
}

class _RetirementElderDetailsPageState extends State<RetirementElderDetailsPage> with TickerProviderStateMixin {
  final _api = RetirementHomeApi();
  final _medApi = RetirementMedicationApi();

  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _elder;
  List<Map<String, dynamic>> _healthLogs = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _medLogs = [];

  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this); // Simplified to 4 Oversight Tabs
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getElderDetails(widget.elderId),
        _api.getElderHealthLogs(widget.elderId, limit: 20),
        _api.getElderLocationHistory(widget.elderId, limit: 50),
        _medApi.getMedicationLogs(widget.elderId),
      ]);

      _elder = results[0] as Map<String, dynamic>;
      _healthLogs = results[1] as List<Map<String, dynamic>>;
      _locations = results[2] as List<Map<String, dynamic>>;
      _medLogs = results[3] as List<Map<String, dynamic>>;

      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: _cream, body: Center(child: CircularProgressIndicator(color: _deepNavy)));
    
    final name = (_elder?['name'] ?? 'Resident').toString();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _deepNavy,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _deepNavy,
          unselectedLabelColor: _denim,
          indicatorColor: _sage,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Health Vitals'),
            Tab(text: 'GPS History'),
            Tab(text: 'Medication Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _profileTab(),
          _listTab(_healthLogs, Icons.favorite_rounded, "vitals"),
          _listTab(_locations, Icons.location_on_rounded, "location history"),
          _listTab(_medLogs, Icons.medication_rounded, "medication administrations"),
        ],
      ),
    );
  }

  Widget _profileTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _bentoBox("Facility Record", [
          _row("Age", "${_elder?['age']} Years"),
          _row("Home City", "${_elder?['location']}"),
          _row("Last Check-in", "${_elder?['last_check_in'] ?? 'Unknown'}"),
        ]),
        const SizedBox(height: 20),
        _bentoBox("Staff in Charge", [
          _row("Caregiver", "${_elder?['caregiver_name'] ?? 'None'}"),
          _row("Phone", "${_elder?['caregiver_phone'] ?? '-'}"),
        ]),
      ],
    );
  }

  Widget _listTab(List<Map<String, dynamic>> data, IconData icon, String type) {
    if (data.isEmpty) return Center(child: Text("No $type recorded yet.", style: const TextStyle(color: _denim)));
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: data.length,
      itemBuilder: (context, i) => _logCard(data[i], icon),
    );
  }

  Widget _bentoBox(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _deepNavy)),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _denim, fontWeight: FontWeight.w600)),
          Text(val, style: const TextStyle(color: _deepNavy, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _logCard(Map<String, dynamic> item, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: _cream, child: Icon(icon, color: _sage, size: 20)),
        title: Text(item.values.first.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("Recorded at: ${item['date'] ?? item['recorded_at'] ?? 'Today'}", style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
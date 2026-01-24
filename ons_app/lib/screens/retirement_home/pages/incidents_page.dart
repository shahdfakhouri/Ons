import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'incident_details_page.dart';

class RetirementIncidentsPage extends StatefulWidget {
  const RetirementIncidentsPage({super.key});

  @override
  State<RetirementIncidentsPage> createState() => _RetirementIncidentsPageState();
}

class _RetirementIncidentsPageState extends State<RetirementIncidentsPage> {
  final _api = RetirementHomeApi();

  // 🎨 Ons Palette
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;
  String _status = 'all';
  List<Map<String, dynamic>> _incidents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.getIncidents(status: _status);
      setState(() {
        _incidents = list;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // UI Helper for Creating Incident (Enhanced Dialog)
  Future<void> _createIncident() async {
    // ... logic same as your original, but style the dialog with _deepNavy ...
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
          _buildHeader(),
          const SizedBox(height: 32),
          if (_incidents.isEmpty)
            _buildEmptyState()
          else
            ..._incidents.map((i) => _buildIncidentBento(i)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Incidents', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _deepNavy, letterSpacing: -1)),
            Text('Monitoring facility safety logs', style: TextStyle(color: _denim, fontSize: 16)),
          ],
        ),
        Row(
          children: [
            _buildFilter(),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: _createIncident,
              icon: const Icon(Icons.add, color: _cream),
              style: IconButton.styleFrom(backgroundColor: _deepNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: DropdownButton<String>(
        value: _status,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All')),
          DropdownMenuItem(value: 'open', child: Text('Open')),
          DropdownMenuItem(value: 'investigating', child: Text('Investigating')),
          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() => _status = v);
          _load();
        },
      ),
    );
  }

  Widget _buildIncidentBento(Map<String, dynamic> i) {
    final severity = (i['severity'] ?? 'medium').toString().toLowerCase();
    final Color sevColor = severity == 'high' ? Colors.redAccent : (severity == 'medium' ? Colors.orange : _sage);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RetirementIncidentDetailsPage(incidentId: i['incident_id'])),
        ).then((_) => _load()),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              _severityIcon(sevColor, severity == 'high'),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((i['type'] ?? 'Incident').toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: sevColor, letterSpacing: 1)),
                    Text(i['elder_name'] ?? 'Unknown Resident', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _deepNavy)),
                    Text("Status: ${i['status']}", style: const TextStyle(color: _denim, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _denim, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _severityIcon(Color color, bool pulse) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(pulse ? Icons.error_outline_rounded : Icons.assignment_late_rounded, color: color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: const Center(child: Text("No incident logs found.", style: TextStyle(color: _denim, fontStyle: FontStyle.italic))),
    );
  }
}
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

  Future<void> _createIncident() async {
    // Styling the dialog with ONS brand colors
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("New Log", style: TextStyle(color: _deepNavy, fontWeight: FontWeight.bold)),
        content: const Text("Would you like to log a new facility incident?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: _denim))),
          FilledButton(
            onPressed: () { Navigator.pop(context); /* Implementation of Create */ },
            style: FilledButton.styleFrom(backgroundColor: _deepNavy),
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _deepNavy));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return RefreshIndicator(
      onRefresh: _load,
      color: _deepNavy,
      child: ListView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 24),
          if (_incidents.isEmpty)
            _buildEmptyState(isMobile)
          else
            ..._incidents.map((i) => _buildIncidentBento(i, isMobile)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incidents', 
          style: TextStyle(
            fontSize: isMobile ? 28 : 34, 
            fontWeight: FontWeight.w900, 
            color: _deepNavy, 
            letterSpacing: -1
          )
        ),
        Text(
          'Monitoring facility safety logs', 
          style: TextStyle(color: _denim, fontSize: isMobile ? 13 : 16)
        ),
      ],
    );

    final actionSection = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilter(),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: _createIncident,
          icon: const Icon(Icons.add, color: _cream),
          style: IconButton.styleFrom(
            backgroundColor: _deepNavy, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(48, 48)
          ),
        ),
      ],
    );

    return isMobile 
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleSection,
            const SizedBox(height: 20),
            actionSection,
          ],
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            titleSection,
            actionSection,
          ],
        );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: DropdownButton<String>(
        value: _status,
        underline: const SizedBox(),
        icon: const Icon(Icons.filter_list_rounded, color: _deepNavy, size: 20),
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

  Widget _buildIncidentBento(Map<String, dynamic> i, bool isMobile) {
    final severity = (i['severity'] ?? 'medium').toString().toLowerCase();
    final Color sevColor = severity == 'high' ? Colors.redAccent : (severity == 'medium' ? Colors.orange : _sage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RetirementIncidentDetailsPage(incidentId: i['incident_id'])),
        ).then((_) => _load()),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Row(
            children: [
              _severityIcon(sevColor, severity == 'high', isMobile),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (i['type'] ?? 'Incident').toString().toUpperCase(), 
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: sevColor, letterSpacing: 1)
                    ),
                    Text(
                      i['elder_name'] ?? 'Unknown Resident', 
                      style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w800, color: _deepNavy),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Status: ${i['status']}", 
                      style: const TextStyle(color: _denim, fontSize: 12)
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _denim, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _severityIcon(Color color, bool pulse, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(
        pulse ? Icons.error_outline_rounded : Icons.assignment_late_rounded, 
        color: color, 
        size: isMobile ? 20 : 24
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 40 : 60),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Icon(Icons.description_outlined, color: _sage, size: 48),
          const SizedBox(height: 16),
          Text(
            "No incident logs found.", 
            textAlign: TextAlign.center,
            style: TextStyle(color: _denim, fontStyle: FontStyle.italic, fontSize: isMobile ? 14 : 16)
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'package:intl/intl.dart';

class RetirementAlertsPage extends StatefulWidget {
  const RetirementAlertsPage({super.key});

  @override
  State<RetirementAlertsPage> createState() => _RetirementAlertsPageState();
}

class _RetirementAlertsPageState extends State<RetirementAlertsPage> {
  final _api = RetirementHomeApi();

  // 🎨 Your Signature Theme Palette
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _alerts = [];
  String _status = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.getAlerts(status: _status, limit: 100);
      setState(() {
        _alerts = list;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
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
          _buildHeader(),
          const SizedBox(height: 32),
          if (_alerts.isEmpty) 
            _buildEmptyState("No active alerts found.")
          else 
            ..._alerts.map((a) => _buildAlertCard(a)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Alerts', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _deepNavy, letterSpacing: -1)),
            Text('Real-time monitoring of resident safety', style: TextStyle(color: _denim.withOpacity(0.8), fontSize: 16)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: DropdownButton<String>(
            value: _status,
            underline: const SizedBox(),
            icon: const Icon(Icons.filter_list_rounded, color: _deepNavy),
            items: const [
              DropdownMenuItem(value: 'open', child: Text('Open')),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              DropdownMenuItem(value: 'all', child: Text('All')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _status = v);
              _load();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> a) {
    final severity = (a['severity'] ?? 'warning').toString().toLowerCase();
    
    // Assign semantic colors based on severity
    final Color sevColor = severity == 'critical' 
        ? Colors.redAccent 
        : (severity == 'warning' ? Colors.orange : _sage);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: sevColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(
                severity == 'critical' ? Icons.gpp_maybe_rounded : Icons.notifications_active_rounded, 
                color: sevColor, 
                size: 24
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (a['type'] ?? 'Alert').toString().toUpperCase(), 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: sevColor, letterSpacing: 1.2)
                      ),
                      Text(
                        _formatDate(a['created_at']), 
                        style: const TextStyle(color: _denim, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (a['elder_name'] ?? 'Facility').toString(), 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _deepNavy)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (a['message'] ?? '').toString(), 
                    style: TextStyle(color: _denim.withOpacity(0.8), fontSize: 15, height: 1.4)
                  ),
                  const SizedBox(height: 16),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "STATUS: ${(a['status'] ?? 'open').toString().toUpperCase()}",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _deepNavy),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('HH:mm • MMM d').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        children: [
          const Icon(Icons.notifications_none_rounded, color: _sage, size: 64),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: _denim, fontStyle: FontStyle.italic, fontSize: 16)),
        ],
      ),
    );
  }
}
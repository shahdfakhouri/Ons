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

    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: _load,
      color: _deepNavy,
      child: ListView(
        // Responsive padding
        padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
        children: [
          _buildHeader(isSmallScreen),
          const SizedBox(height: 24),
          if (_alerts.isEmpty) 
            _buildEmptyState("No active alerts found.", isSmallScreen)
          else 
            ..._alerts.map((a) => _buildAlertCard(a, isSmallScreen)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Alerts', 
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 34, 
            fontWeight: FontWeight.w900, 
            color: _deepNavy, 
            letterSpacing: -1
          )
        ),
        Text(
          'Real-time monitoring of resident safety', 
          style: TextStyle(color: _denim.withOpacity(0.8), fontSize: isSmallScreen ? 13 : 16)
        ),
      ],
    );

    final filterWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
      ),
      child: DropdownButton<String>(
        value: _status,
        underline: const SizedBox(),
        icon: const Icon(Icons.filter_list_rounded, color: _deepNavy, size: 20),
        items: const [
          DropdownMenuItem(value: 'open', child: Text('Open', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 'resolved', child: Text('Resolved', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 'all', child: Text('All', style: TextStyle(fontSize: 14))),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() => _status = v);
          _load();
        },
      ),
    );

    // Stack vertically on mobile, horizontally on desktop
    return isSmallScreen 
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleWidget,
            const SizedBox(height: 16),
            filterWidget,
          ],
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            titleWidget,
            filterWidget,
          ],
        );
  }

  Widget _buildAlertCard(Map<String, dynamic> a, bool isSmallScreen) {
    final severity = (a['severity'] ?? 'warning').toString().toLowerCase();
    final Color sevColor = severity == 'critical' 
        ? Colors.redAccent 
        : (severity == 'warning' ? Colors.orange : _sage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: sevColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(
                severity == 'critical' ? Icons.gpp_maybe_rounded : Icons.notifications_active_rounded, 
                color: sevColor, 
                size: isSmallScreen ? 20 : 24
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (a['type'] ?? 'Alert').toString().toUpperCase(), 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: sevColor, letterSpacing: 1.0)
                      ),
                      Text(
                        _formatDate(a['created_at']), 
                        style: const TextStyle(color: _denim, fontSize: 11, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (a['elder_name'] ?? 'Facility').toString(), 
                    style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w800, color: _deepNavy)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (a['message'] ?? '').toString(), 
                    style: TextStyle(color: _denim.withOpacity(0.8), fontSize: 14, height: 1.3)
                  ),
                  const SizedBox(height: 12),
                  _StatusBadge(status: (a['status'] ?? 'open').toString()),
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

  Widget _buildEmptyState(String msg, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 40 : 60),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(Icons.notifications_none_rounded, color: _sage, size: isSmallScreen ? 48 : 64),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: _denim, fontStyle: FontStyle.italic, fontSize: 14)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8D4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "STATUS: ${status.toUpperCase()}",
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF313647)),
      ),
    );
  }
}
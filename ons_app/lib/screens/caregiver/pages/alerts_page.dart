import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/caregiver_api.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final _api = CaregiverApi();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _alerts = [];

  String _fmt(dynamic v) {
    if (v == null) return '-';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return DateFormat('MMM d • h:mm a').format(dt);
    } catch (_) {
      return v.toString();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final alerts = await _api.getMyAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _alerts = [];
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4), // Ons cream background
      appBar: AppBar(
        title: const Text("Critical Alerts", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _buildBody(cs, tt),
    );
  }

  Widget _buildBody(ColorScheme cs, TextTheme tt) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) return _buildErrorState(cs, tt);

    if (_alerts.isEmpty) return _buildEmptyState(cs, tt);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final a = _alerts[index];
          return _AlertCard(alert: a, timestamp: _fmt(a['created_at']), cs: cs, tt: tt);
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: cs.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("All Clear", style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
          Text("No active alerts at this time.", style: tt.bodyMedium?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text("Connection Error", style: tt.titleLarge),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: tt.bodySmall),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text("Try Again")),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final String timestamp;
  final ColorScheme cs;
  final TextTheme tt;

  const _AlertCard({required this.alert, required this.timestamp, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    final severity = (alert['severity'] ?? 'medium').toString().toLowerCase();
    
    // Determine status color based on severity
    Color statusColor;
    if (severity == 'high' || severity == 'critical') {
      statusColor = Colors.redAccent;
    } else if (severity == 'medium') {
      statusColor = Colors.orangeAccent;
    } else {
      statusColor = Colors.blueAccent;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored Severity Bar
              Container(width: 6, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              severity.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(timestamp, style: tt.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        alert['message'] ?? 'Action Required',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(
                            alert['elder_name'] ?? 'Unknown Resident',
                            style: tt.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text("•", style: TextStyle(color: Colors.grey)),
                          ),
                          Text(
                            alert['type'] ?? 'General',
                            style: tt.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
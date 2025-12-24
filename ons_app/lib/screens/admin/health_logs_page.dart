import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class HealthLogsPage extends StatefulWidget {
  const HealthLogsPage({super.key});

  @override
  State<HealthLogsPage> createState() => _HealthLogsPageState();
}

class _HealthLogsPageState extends State<HealthLogsPage> {
  final AdminApi _api = AdminApi();

  bool _loading = true;
  String? _error;
  List _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _api.getHealthSummary();
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  // UI-only quick flag
  String _riskLabel(Map row) {
    final tempStr = _v(row['temperature'], fallback: '');
    final bp = _v(row['blood_pressure'], fallback: '');

    final t = double.tryParse(tempStr.replaceAll('°C', '').trim());
    if (t != null && t >= 38.0) return 'High Temp';

    final parts = bp.split('/');
    if (parts.isNotEmpty) {
      final sys = int.tryParse(parts.first.trim());
      if (sys != null && sys >= 140) return 'High BP';
    }

    return 'Normal';
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'High Temp':
      case 'High BP':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Health Logs',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _rows.isEmpty
                          ? const Center(child: Text('No health summaries found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _rows.length,
                              itemBuilder: (context, index) {
                                final row = _rows[index] as Map;

                                final elderName = _v(row['elder_name']);
                                final lastCheckin = _v(row['last_checkin']);
                                final date = _v(row['date']);
                                final bp = _v(row['blood_pressure']);
                                final sugar = _v(row['blood_sugar']);
                                final temp = _v(row['temperature']);
                                final notes = _v(row['notes'], fallback: '');

                                final risk = _riskLabel(row);
                                final riskColor = _riskColor(risk);

                                return _HealthSummaryCard(
                                  elderName: elderName,
                                  lastCheckin: lastCheckin,
                                  date: date,
                                  bp: bp,
                                  sugar: sugar,
                                  temp: temp,
                                  notes: notes,
                                  risk: risk,
                                  riskColor: riskColor,
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  final String elderName;
  final String lastCheckin;
  final String date;
  final String bp;
  final String sugar;
  final String temp;
  final String notes;

  final String risk;
  final Color riskColor;

  const _HealthSummaryCard({
    required this.elderName,
    required this.lastCheckin,
    required this.date,
    required this.bp,
    required this.sugar,
    required this.temp,
    required this.notes,
    required this.risk,
    required this.riskColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    elderName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    risk,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Last check-in: $lastCheckin',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withOpacity(0.75),
                  ),
            ),
            const SizedBox(height: 6),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetricPill(label: 'BP', value: bp),
                _MetricPill(label: 'Sugar', value: sugar),
                _MetricPill(label: 'Temp', value: temp),
                _MetricPill(label: 'Date', value: date),
              ],
            ),

            if (notes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Notes: $notes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.85),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

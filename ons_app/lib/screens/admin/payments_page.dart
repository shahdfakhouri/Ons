import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final AdminApi _api = AdminApi();

  bool _loading = true;
  String? _error;

  Map<String, dynamic> _overview = {};
  List _revenueByRole = [];
  List _paymentStatus = [];

  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? get _fromStr => _from == null ? null : _fmt(_from!);
  String? get _toStr => _to == null ? null : _fmt(_to!);

  num _asNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final overview = await _api.getFinanceOverview(from: _fromStr, to: _toStr);
      final revenue = await _api.getRevenueByRole(from: _fromStr, to: _toStr);
      final payments = await _api.getPaymentStats(from: _fromStr, to: _toStr);

      setState(() {
        _overview = overview;
        _revenueByRole = revenue;
        _paymentStatus = payments;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _to = picked);
  }

  void _clearFilters() {
    setState(() {
      _from = null;
      _to = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Payments & Payouts',
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
              : ListView(
                  children: [
                    _FiltersBar(
                      from: _from,
                      to: _to,
                      onPickFrom: _pickFrom,
                      onPickTo: _pickTo,
                      onApply: _load,
                      onClear: _clearFilters,
                    ),
                    const SizedBox(height: 16),

                    // Overview cards
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricCard(
                          title: 'Total payments',
                          value: '${_asNum(_overview['total_payments']).toInt()}',
                        ),
                        _MetricCard(
                          title: 'Total revenue',
                          value: _asNum(_overview['total_revenue']).toStringAsFixed(2),
                        ),
                        _MetricCard(
                          title: 'Platform revenue',
                          value: _asNum(_overview['platform_revenue']).toStringAsFixed(2),
                        ),
                        _MetricCard(
                          title: 'Caregiver payouts',
                          value: _asNum(_overview['caregiver_payouts']).toStringAsFixed(2),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    Text(
                      'Revenue by role',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: _revenueByRole.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No revenue data for this range.'),
                            )
                          : Column(
                              children: _revenueByRole.map((r) {
                                final role = r['role']?.toString() ?? '-';
                                final total = _asNum(r['total_earned']).toStringAsFixed(2);
                                return ListTile(
                                  title: Text(role),
                                  trailing: Text(total),
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 22),
                    Text(
                      'Payment status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: _paymentStatus.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No payment status data for this range.'),
                            )
                          : Column(
                              children: _paymentStatus.map((p) {
                                final status = p['status']?.toString() ?? '-';
                                final total = _asNum(p['total']).toInt();
                                return ListTile(
                                  title: Text(status),
                                  trailing: Text(total.toString()),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _FiltersBar({
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onApply,
    required this.onClear,
  });

  String _label(DateTime? d) {
    if (d == null) return '--';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Filter by date:', style: Theme.of(context).textTheme.bodyMedium),
            OutlinedButton.icon(
              onPressed: onPickFrom,
              icon: const Icon(Icons.date_range),
              label: Text('From: ${_label(from)}'),
            ),
            OutlinedButton.icon(
              onPressed: onPickTo,
              icon: const Icon(Icons.date_range),
              label: Text('To: ${_label(to)}'),
            ),
            ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.search),
              label: const Text('Apply'),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

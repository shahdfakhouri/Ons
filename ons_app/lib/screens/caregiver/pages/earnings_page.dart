import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/payment_api.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  final PaymentApi _api = PaymentApi();
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _rev = {};
  List<Map<String, dynamic>> _tx = [];

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
      final rev = await _api.getReceiverRevenue();
      final tx = await _api.getReceiverTransactions(limit: 100);

      setState(() {
        _rev = rev;
        _tx = tx;
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

  String _prettyDate(dynamic raw) {
    final s = _v(raw, fallback: '');
    if (s.isEmpty || s == '-') return '-';
    DateTime? dt = DateTime.tryParse(s);
    dt ??= DateTime.tryParse(s.replaceFirst(' ', 'T'));
    if (dt == null) return s;
    final local = dt.isUtc ? dt.toLocal() : dt;
    return DateFormat('MMM d, yyyy • h:mm a').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorState(cs);

    final total = _rev['receiver_revenue'] ?? _rev['totalRevenue'] ?? _rev['total_revenue'] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 🏆 SECTION 1: Wallet Hero Card
          _buildWalletHeader(total, cs, tt),
          const SizedBox(height: 32),

          // 🏛️ SECTION 2: Transaction History Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transaction History', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('${_tx.length} Records', style: tt.bodySmall?.copyWith(color: cs.secondary)),
            ],
          ),
          const SizedBox(height: 16),

          // 🏛️ SECTION 3: Transaction List
          if (_tx.isEmpty)
            _buildEmptyState(cs)
          else
            ..._tx.map((t) => _buildTransactionItem(t, cs, tt)).toList(),
        ],
      ),
    );
  }

  Widget _buildWalletHeader(dynamic total, ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Balance', style: TextStyle(color: cs.onPrimary.withOpacity(0.8), fontSize: 14)),
              Icon(Icons.account_balance_wallet_rounded, color: cs.onPrimary.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_v(total)}',
            style: tt.headlineLarge?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.onPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, color: cs.onPrimary, size: 14),
                const SizedBox(width: 8),
                Text('Secure Payouts Enabled', style: TextStyle(color: cs.onPrimary, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> t, ColorScheme cs, TextTheme tt) {
    final fromLabel = (t['from_name']?.toString().trim().isNotEmpty == true)
        ? t['from_name']
        : '${t['from_role'] ?? 'System'}';
    
    final isIncome = _v(t['type']).toLowerCase().contains('payment') || _v(t['type']).toLowerCase().contains('credit');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isIncome ? Colors.green.withOpacity(0.1) : cs.surfaceVariant,
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: isIncome ? Colors.green : cs.onSurfaceVariant,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_v(t['type']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('From: $fromLabel', style: tt.bodySmall?.copyWith(color: cs.secondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? "+" : ""}\$${_v(t['amount'])}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : cs.onSurface,
                ),
              ),
              Text(_prettyDate(t['created_at']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: cs.outline),
            const SizedBox(height: 16),
            const Text('No transactions to show yet.'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 48),
          const SizedBox(height: 16),
          Text('Error: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'payment_details_page.dart';

class RetirementPaymentsPage extends StatefulWidget {
  const RetirementPaymentsPage({super.key});

  @override
  State<RetirementPaymentsPage> createState() => _RetirementPaymentsPageState();
}

class _RetirementPaymentsPageState extends State<RetirementPaymentsPage> {
  final _api = RetirementHomeApi();

  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;
  String _status = 'all';
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.getPayments(status: _status);
      setState(() {
        _payments = list;
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
          if (_payments.isEmpty)
            _buildEmptyState("No financial records found for this home.")
          else
            ..._payments.map((p) => _buildPaymentBentoCard(p)),
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
            Text('Financials', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _deepNavy, letterSpacing: -1)),
            Text('Monitor revenue and family subscriptions', style: TextStyle(color: _denim, fontSize: 16)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: DropdownButton<String>(
            value: _status,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'paid', child: Text('Paid')),
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

  Widget _buildPaymentBentoCard(Map<String, dynamic> p) {
    final id = (p['payment_id'] ?? 0) as num;
    final status = (p['status'] ?? 'pending').toString().toLowerCase();
    final Color statusColor = status == 'paid' ? _sage : Colors.orangeAccent;

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
          MaterialPageRoute(builder: (_) => RetirementPaymentDetailsPage(paymentId: id.toInt())),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.account_balance_wallet_rounded, color: statusColor, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['family_name'] ?? 'Family Record', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _deepNavy)),
                    Text(p['purpose'] ?? 'Subscription Fee', style: const TextStyle(color: _denim, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${p['amount']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _deepNavy)),
                  Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Center(child: Text(msg, style: const TextStyle(color: _denim, fontStyle: FontStyle.italic))),
    );
  }
}
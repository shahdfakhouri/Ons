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

    // Adaptive breakpoint for mobile/tablet screens
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return RefreshIndicator(
      onRefresh: _load,
      color: _deepNavy,
      child: ListView(
        // Dynamic padding: 16px for mobile, 32px for desktop
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 24),
          if (_payments.isEmpty)
            _buildEmptyState("No financial records found.", isMobile)
          else
            ..._payments.map((p) => _buildPaymentBentoCard(p, isMobile)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financials', 
          style: TextStyle(
            fontSize: isMobile ? 28 : 34, 
            fontWeight: FontWeight.w900, 
            color: _deepNavy, 
            letterSpacing: -1
          )
        ),
        Text(
          'Monitor revenue and family subscriptions', 
          style: TextStyle(color: _denim, fontSize: isMobile ? 13 : 16)
        ),
      ],
    );

    final filterDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]
      ),
      child: DropdownButton<String>(
        value: _status,
        underline: const SizedBox(),
        icon: const Icon(Icons.filter_list_rounded, color: _deepNavy, size: 20),
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
    );

    // Responsive: Column for Mobile, Row for Desktop
    return isMobile 
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleSection,
            const SizedBox(height: 16),
            filterDropdown,
          ],
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            titleSection,
            filterDropdown,
          ],
        );
  }

  Widget _buildPaymentBentoCard(Map<String, dynamic> p, bool isMobile) {
    final id = (p['payment_id'] ?? 0) as num;
    final status = (p['status'] ?? 'pending').toString().toLowerCase();
    final Color statusColor = status == 'paid' ? _sage : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RetirementPaymentDetailsPage(paymentId: id.toInt())),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(
                  Icons.account_balance_wallet_rounded, 
                  color: statusColor, 
                  size: isMobile ? 20 : 24
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['family_name'] ?? 'Family Record', 
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18, 
                        fontWeight: FontWeight.w800, 
                        color: _deepNavy
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      p['purpose'] ?? 'Subscription Fee', 
                      style: const TextStyle(color: _denim, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${p['amount']}', 
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20, 
                      fontWeight: FontWeight.w900, 
                      color: _deepNavy
                    )
                  ),
                  Text(
                    status.toUpperCase(), 
                    style: TextStyle(
                      fontSize: 9, 
                      fontWeight: FontWeight.w900, 
                      color: statusColor, 
                      letterSpacing: 0.5
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, color: _sage, size: 48),
          const SizedBox(height: 16),
          Text(
            msg, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: _denim, fontStyle: FontStyle.italic, fontSize: 14)
          ),
        ],
      ),
    );
  }
}
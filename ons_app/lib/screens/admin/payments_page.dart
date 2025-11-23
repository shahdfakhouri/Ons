import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Payments & Payouts',
      child: Center(
        child: Text(
          'Here you will list subscriptions, invoices,\n'
          'and caregiver payouts (dummy for now).',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/screens/caregiver/caregiver_layout.dart';

class CaregiverPaymentsPage extends StatelessWidget {
  const CaregiverPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final payouts = [
      PaymentItem(
        period: 'Nov 2025',
        amount: '₪ 1,250',
        status: 'Paid',
      ),
      PaymentItem(
        period: 'Oct 2025',
        amount: '₪ 980',
        status: 'Paid',
      ),
      PaymentItem(
        period: 'Sep 2025',
        amount: '₪ 1,430',
        status: 'Pending',
      ),
    ];

    return CaregiverLayout(
      title: 'Payments',
      child: ListView.separated(
        itemCount: payouts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = payouts[index];
          final isPaid = p.status == 'Paid';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.onSurface.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isPaid ? Icons.check_circle : Icons.schedule,
                  color: isPaid ? Colors.green : AppTheme.denim,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.period,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepNavy,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.status,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: isPaid
                                  ? Colors.green[700]
                                  : colors.onSurface.withOpacity(0.8),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  p.amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepNavy,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PaymentItem {
  final String period;
  final String amount;
  final String status;

  PaymentItem({
    required this.period,
    required this.amount,
    required this.status,
  });
}

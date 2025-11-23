import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';

class MatchingOverviewPage extends StatelessWidget {
  const MatchingOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Matching Overview',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.elderly),
              title: const Text('Elder: Abu Ahmad'),
              subtitle: const Text(
                'Matched with caregiver: Sara\nStatus: Pending admin review',
              ),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Review'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.elderly),
              title: const Text('Elder: Um Omar'),
              subtitle: const Text('Matched with RH: Al Rahma Home'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Review'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

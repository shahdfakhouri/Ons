import 'package:flutter/material.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/services/dio_factory.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'elder_details_page.dart';

class EldersMonitoringPage extends StatelessWidget {
  const EldersMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = RetirementHomeApi(DioFactory.create());

    return RetirementHomeLayout(
      title: 'Elders monitoring',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: api.getEldersMonitoring(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final elders = snap.data ?? [];
          if (elders.isEmpty) return const Center(child: Text('No elders found.'));

          return ListView.separated(
            itemCount: elders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final e = elders[i];
              final id = (e['elder_id'] ?? 0);
              final name = (e['elder_name'] ?? 'Unknown').toString();
              final caregiver = (e['caregiver_name'] ?? 'Unassigned').toString();
              final lastHealthAt = (e['last_health_at'] ?? '-').toString();
              final bp = (e['blood_pressure'] ?? '-').toString();
              final sugar = (e['blood_sugar'] ?? '-').toString();
              final temp = (e['temperature'] ?? '-').toString();

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                    'Caregiver: $caregiver\nLast health: $lastHealthAt\nBP: $bp | Sugar: $sugar | Temp: $temp',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ElderDetailsPage(elderId: int.tryParse(id.toString()) ?? 0),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

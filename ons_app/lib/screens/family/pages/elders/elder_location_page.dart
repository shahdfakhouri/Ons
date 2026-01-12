import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class ElderLocationPage extends StatefulWidget {
  final int elderId;
  const ElderLocationPage({super.key, required this.elderId});

  @override
  State<ElderLocationPage> createState() => _ElderLocationPageState();
}

class _ElderLocationPageState extends State<ElderLocationPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    final elderId = widget.elderId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SectionTitle('Latest'),
          FutureBuilder(
            future: api.getLatestLocation(elderId),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final latest = (data['latest'] as Map?) ?? {};

              if (latest.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No location yet.')));
              }

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.my_location),
                  title: Text('Lat: ${latest['lat'] ?? latest['latitude'] ?? '-'}  •  Lng: ${latest['lng'] ?? latest['longitude'] ?? '-'}'),
                  subtitle: Text('At: ${latest['recorded_at'] ?? latest['created_at'] ?? ''}'),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          const SectionTitle('History'),
          _ListBlock(
            future: api.getLocationHistory(elderId),
            listKey: 'history',
            icon: Icons.location_on,
            title: (m) => 'Lat: ${m['lat'] ?? m['latitude'] ?? '-'}  •  Lng: ${m['lng'] ?? m['longitude'] ?? '-'}',
            subtitle: (m) => (m['recorded_at'] ?? m['created_at'] ?? '').toString(),
          ),

          const SizedBox(height: 12),
          const SectionTitle('Safe zones'),
          _ListBlock(
            future: api.getSafeZones(elderId),
            listKey: 'zones',
            icon: Icons.shield,
            title: (m) => (m['name'] ?? m['label'] ?? 'Zone').toString(),
            subtitle: (m) => 'Radius: ${m['radius'] ?? '-'} • Center: ${m['center_lat'] ?? '-'}, ${m['center_lng'] ?? '-'}',
          ),
        ],
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final String listKey;
  final IconData icon;
  final String Function(Map m) title;
  final String Function(Map m) subtitle;

  const _ListBlock({
    required this.future,
    required this.listKey,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
        }
        if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

        final data = (snap.data as Map<String, dynamic>? ?? {});
        final list = (data[listKey] as List?) ?? const [];

        if (list.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No data yet.')));

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = list[i] as Map;
              return ListTile(
                leading: Icon(icon),
                title: Text(title(m), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(subtitle(m)),
              );
            },
          ),
        );
      },
    );
  }
}

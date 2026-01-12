import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_api.dart';

class SafeZonesPage extends StatefulWidget {
  const SafeZonesPage({super.key});

  @override
  State<SafeZonesPage> createState() => _SafeZonesPageState();
}

class _SafeZonesPageState extends State<SafeZonesPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;
  List<dynamic> zones = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      zones = await api.safeZones();
      setState(() => loading = false);
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Zones'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: zones.isEmpty
          ? const Center(child: Text('No safe zones yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: zones.length,
              itemBuilder: (_, i) {
                final z = zones[i] as Map;
                final name = z['name']?.toString() ?? 'Zone';
                final lat = z['latitude']?.toString() ?? '-';
                final lng = z['longitude']?.toString() ?? '-';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.shield),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('($lat, $lng)'),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/screens/admin/gps_history_page.dart';
import 'package:ons_app/services/admin_api.dart';

class GpsOverviewPage extends StatefulWidget {
  const GpsOverviewPage({super.key});

  @override
  State<GpsOverviewPage> createState() => _GpsOverviewPageState();
}

class _GpsOverviewPageState extends State<GpsOverviewPage> {
  final AdminApi _api = AdminApi();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getGpsOverview();
      setState(() {
        _rows = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _rows = [];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;

    return _rows.where((r) {
      final elderName = _v(r['elder_name']).toLowerCase();
      final elderId = _v(r['elder_id']).toLowerCase();
      final place = _v(r['place_name'], fallback: '').toLowerCase(); // ✅ NEW searchable
      return elderName.contains(q) || elderId.contains(q) || place.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'GPS Overview',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 320,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Search (elder name / id / place)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                            Text('Total: ${_filtered.length}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text('No GPS data found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final r = _filtered[index];

                                final elderId = _v(r['elder_id']);
                                final elderName = _v(r['elder_name']);
                                final lastSeen = _v(r['last_seen']);
                                final place = _v(r['place_name'], fallback: '');
final lat = _v(r['latitude']);
final lng = _v(r['longitude']);

final subtitleLines = <String>[
  'Last seen: $lastSeen',
  if (place.isNotEmpty) 'Place: $place'
  else ...[
    'Lat: $lat',
    'Lng: $lng',
  ],
];

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.location_on_outlined),
                                    title: Text('$elderName (ID: $elderId)'),
                                    subtitle: Text(subtitleLines.join('\n')),
                                    trailing: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => GpsHistoryPage(
                                              elderId: elderId,
                                              elderName: elderName,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('History'),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
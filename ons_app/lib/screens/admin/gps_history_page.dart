import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class GpsHistoryPage extends StatefulWidget {
  final String elderId;
  final String elderName;

  const GpsHistoryPage({
    super.key,
    required this.elderId,
    required this.elderName,
  });

  @override
  State<GpsHistoryPage> createState() => _GpsHistoryPageState();
}

class _GpsHistoryPageState extends State<GpsHistoryPage> {
  final AdminApi _api = AdminApi();

  bool _loading = true;
  String? _error;
  List _history = [];

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
      final rows = await _api.getGpsHistory(widget.elderId);
      setState(() {
        _history = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _history = [];
        _loading = false;
      });
    }
  }

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'GPS History - ${widget.elderName}',
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
              : _history.isEmpty
                  ? const Center(child: Text('No location history found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final h = _history[index] as Map;

                        final recordedAt = _v(h['recorded_at']);
                        final lat = _v(h['latitude']);
                        final lng = _v(h['longitude']);

                        // ✅ NEW (from backend)
                        final place = _v(h['place_name'], fallback: '');

                        final subtitleLines = <String>[
                          if (place.isNotEmpty) 'Place: $place',
                          'Lat: $lat',
                          'Lng: $lng',
                        ];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.my_location_outlined),
                            title: Text('Recorded: $recordedAt'),
                            subtitle: Text(subtitleLines.join('\n')),
                          ),
                        );
                      },
                    ),
    );
  }
}
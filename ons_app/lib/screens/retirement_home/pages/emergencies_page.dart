import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'package:intl/intl.dart';

class RetirementEmergenciesPage extends StatefulWidget {
  const RetirementEmergenciesPage({super.key});

  @override
  State<RetirementEmergenciesPage> createState() => _RetirementEmergenciesPageState();
}

class _RetirementEmergenciesPageState extends State<RetirementEmergenciesPage> {
  final _api = RetirementHomeApi();

  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _statusFilter = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.getEmergencies();
      final filtered = _statusFilter == 'all'
          ? list
          : list.where((e) => (e['status'] ?? '').toString().toLowerCase() == _statusFilter).toList();

      setState(() {
        _items = filtered;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _act(int emergencyId, bool accept) async {
    try {
      if (accept) {
        await _api.acceptEmergency(emergencyId);
      } else {
        await _api.rejectEmergency(emergencyId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Responsibility Accepted ✅' : 'Request Declined ❎'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: accept ? _sage : Colors.redAccent,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _deepNavy));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return RefreshIndicator(
      onRefresh: _load,
      color: _deepNavy,
      child: ListView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 24),
          if (_items.isEmpty)
            _buildEmptyState(isMobile)
          else
            ..._items.map((e) => _buildEmergencyBento(e, isMobile)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dispatch Center', 
          style: TextStyle(
            fontSize: isMobile ? 26 : 34, 
            fontWeight: FontWeight.w900, 
            color: _deepNavy, 
            letterSpacing: -1
          )
        ),
        Text(
          'Manage incoming resident SOS requests', 
          style: TextStyle(color: _denim.withOpacity(0.8), fontSize: isMobile ? 13 : 16)
        ),
      ],
    );

    final filterDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: DropdownButton<String>(
        value: _statusFilter,
        underline: const SizedBox(),
        icon: const Icon(Icons.filter_list_rounded, color: _deepNavy, size: 20),
        items: const [
          DropdownMenuItem(value: 'open', child: Text('Open SOS')),
          DropdownMenuItem(value: 'assigned', child: Text('Active Dispatch')),
          DropdownMenuItem(value: 'all', child: Text('History')),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() => _statusFilter = v);
          _load();
        },
      ),
    );

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

  Widget _buildEmergencyBento(Map<String, dynamic> e, bool isMobile) {
    final severity = (e['severity'] ?? 'critical').toString().toLowerCase();
    final bool isCritical = severity == 'critical';
    final Color accentColor = isCritical ? Colors.redAccent : _sage;
    
    final id = (e['emergency_id'] ?? e['id'] ?? 0) as num;
    final status = (e['status'] ?? 'unknown').toString();
    final response = (e['response'] ?? 'pending').toString();
    final type = (e['emergency_type'] ?? 'Emergency').toString();
    final distance = e['distance_km'];
    final canRespond = (status == 'open') && (response == 'pending');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 4))],
        border: isCritical ? Border.all(color: Colors.redAccent.withOpacity(0.2), width: 2) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statusBadge(status, response),
                      const Spacer(),
                      Text(_formatTime(e['created_at']), style: const TextStyle(color: _denim, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: accentColor.withOpacity(0.1),
                        child: Icon(Icons.emergency_rounded, color: accentColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$type Alert',
                          style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: _deepNavy),
                        ),
                      ),
                      if (distance != null)
                        Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.w900, color: _denim, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.person_pin_rounded, 'Resident: ${e['elder_name'] ?? 'ID: ${e['elder_id']}'}'),
                  _infoRow(Icons.location_on_rounded, e['address_text'] ?? 'GPS: (${e['latitude']}, ${e['longitude']})'),
                ],
              ),
            ),
            if (canRespond)
              Container(
                decoration: const BoxDecoration(color: _cream),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: isMobile 
                  ? Column(
                      children: [
                        _actionButton(id.toInt(), true, true), // Accept first on mobile
                        const SizedBox(height: 8),
                        _actionButton(id.toInt(), false, true),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _actionButton(id.toInt(), false, false)),
                        const SizedBox(width: 8),
                        Expanded(child: _actionButton(id.toInt(), true, false)),
                      ],
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(int id, bool accept, bool isMobile) {
    if (accept) {
      return FilledButton.icon(
        onPressed: () => _act(id, true),
        style: FilledButton.styleFrom(
          backgroundColor: _sage, 
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        icon: const Icon(Icons.check, color: _deepNavy, size: 18),
        label: const Text('Accept & Dispatch', style: TextStyle(color: _deepNavy, fontWeight: FontWeight.bold, fontSize: 13)),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => _act(id, false),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
        label: const Text('Decline Request', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
      );
    }
  }

  Widget _statusBadge(String status, String response) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _deepNavy, borderRadius: BorderRadius.circular(8)),
      child: Text(
        '${status.toUpperCase()} • ${response.toUpperCase()}',
        style: const TextStyle(color: _cream, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _denim),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: _denim, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('HH:mm').format(dt);
    } catch (_) { return '--:--'; }
  }

  Widget _buildEmptyState(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 60),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: _sage, size: isMobile ? 48 : 64),
          const SizedBox(height: 20),
          Text('Area Secured', style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: _deepNavy)),
          const SizedBox(height: 8),
          Text(
            'No active emergency requests for your facility.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: _denim.withOpacity(0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
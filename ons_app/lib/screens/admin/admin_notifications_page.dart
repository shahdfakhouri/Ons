import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_notifications_api.dart';
import 'package:url_launcher/url_launcher.dart'; // 🚀 Required for Live Map feature

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage>
    with SingleTickerProviderStateMixin {
  
  // 1. Filter State Variables
  String severityFilter = 'all';
  String roleFilter = 'all';
  String searchQuery = ''; // 🚀 New: Search for Fatima Nasser by name
  DateTimeRange? selectedDateRange;

  final AdminNotificationsApi api = AdminNotificationsApi();
  late TabController tabs;

  bool loading = true;
  String? error;

  String healthStatus = 'open';
  List<Map<String, dynamic>> healthAlerts = [];
  List<Map<String, dynamic>> allNotifications = [];

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  // 🚀 Step 1: Live Map Launcher
  Future<void> _openMap(dynamic lat, dynamic lng) async {
    // Standard Google Maps URL format
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri url = Uri.parse(googleMapsUrl);
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open maps application"))
        );
      }
    }
  }

  // 2. Data Loading with Filters
  Future<void> _loadAll() async {
    setState(() { loading = true; error = null; });
    try {
      String? startStr = selectedDateRange?.start.toIso8601String().split('T')[0];
      String? endStr = selectedDateRange?.end.toIso8601String().split('T')[0];

      final alerts = await api.getHealthAlerts(
        status: healthStatus,
        severity: severityFilter,
        startDate: startStr,
        endDate: endStr,
      );

      final all = await api.getAdminNotifications(
        severity: severityFilter,
        role: roleFilter,
        startDate: startStr,
        endDate: endStr,
      );

      setState(() { 
        // 🚀 Step 2: Client-side Search Filtering
        healthAlerts = alerts.where((a) => 
          (a['elder_name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
        
        allNotifications = all; 
        loading = false; 
      });
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  // 3. Icon Helpers for GUI Strength
  IconData _getCategoryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'emergency': return Icons.emergency_share; // 🚀 New Emergency Icon
      case 'payment': return Icons.payments;
      case 'new_user': return Icons.person_add;
      case 'report': return Icons.assignment;
      default: return Icons.notifications;
    }
  }

  Color _getCategoryColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency': return Colors.red;
      case 'payment': return Colors.green;
      case 'new_user': return Colors.blue;
      case 'report': return Colors.orange;
      default: return Colors.blueGrey;
    }
  }

  int _asInt(dynamic x) => int.tryParse('${x ?? ''}') ?? 0;
  bool _asBool(dynamic x) => x == true || x == 1 || '$x' == 'true';

  Future<void> _markRead(int id) async {
    await api.markAsRead(id);
    await _loadAll();
  }

  Future<void> _resolve(int id) async {
    await api.resolveAlert(id);
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Notifications',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    // 🚀 Step 3: Search Bar for Name Resolution
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search for Fatima Nasser or others...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          searchQuery = v;
                          _loadAll();
                        },
                      ),
                    ),
                    
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loadAll,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                        const SizedBox(width: 12),
                        if (tabs.index == 0) ...[
                          const Text('Show: '),
                          DropdownButton<String>(
                            value: healthStatus,
                            items: const [
                              DropdownMenuItem(value: 'open', child: Text('Open Alerts')),
                              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                              DropdownMenuItem(value: 'all', child: Text('All History')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => healthStatus = v);
                              _loadAll();
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAdvancedFilters(),
                    const SizedBox(height: 12),
                    TabBar(
                      controller: tabs,
                      onTap: (_) => setState(() {}),
                      tabs: const [
                        Tab(text: 'Health Alerts'),
                        Tab(text: 'All System Events'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        controller: tabs,
                        children: [
                          _buildHealthAlerts(),
                          _buildAllNotifications(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAdvancedFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          DropdownButton<String>(
            value: severityFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Severities')),
              DropdownMenuItem(value: 'critical', child: Text('🔴 Critical')),
              DropdownMenuItem(value: 'warning', child: Text('🟠 Warning')),
            ],
            onChanged: (v) { setState(() => severityFilter = v!); _loadAll(); },
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: roleFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Roles')),
              DropdownMenuItem(value: 'caregiver', child: Text('Caregivers')),
              DropdownMenuItem(value: 'family', child: Text('Family')),
              DropdownMenuItem(value: 'elder', child: Text('Elder')), // 🚀 Added Elder Role
            ],
            onChanged: (v) { setState(() => roleFilter = v!); _loadAll(); },
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: () async {
              final range = await showDateRangePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2027));
              if (range != null) { setState(() => selectedDateRange = range); _loadAll(); }
            },
            icon: const Icon(Icons.date_range),
            label: Text(selectedDateRange == null ? 'Filter Date' : 'Date Range Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAlerts() {
    if (healthAlerts.isEmpty) return const Center(child: Text('No active medical alerts'));
    return ListView.builder(
      itemCount: healthAlerts.length,
      itemBuilder: (_, i) {
        final a = healthAlerts[i];
        final severity = a['severity'] ?? 'info';
        final isEmergency = a['type'] == 'emergency'; // 🚀 Detection for SOS
        
        return Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: isEmergency || severity == 'critical' ? Colors.red : Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(isEmergency ? Icons.emergency : Icons.warning, color: isEmergency || severity == 'critical' ? Colors.red : Colors.orange),
            title: Text("Alert for ${a['elder_name'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['message']),
                Text("Reported by: ${a['sender_name'] ?? 'System'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                
                // 🚀 Step 4: Map Launcher Button
                if (isEmergency && a['latitude'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _openMap(a['latitude'], a['longitude']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                      icon: const Icon(Icons.location_on, size: 16),
                      label: const Text("VIEW EMERGENCY LOCATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
              ],
            ),
            trailing: healthStatus == 'resolved' ? const Icon(Icons.check_circle, color: Colors.green) : FilledButton(
              onPressed: () => _resolve(a['id']),
              child: const Text('Resolve'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllNotifications() {
    if (allNotifications.isEmpty) return const Center(child: Text('No system events found'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: allNotifications.length,
      itemBuilder: (_, i) {
        final n = allNotifications[i];
        final type = (n['type'] ?? 'system').toString();
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(type).withOpacity(0.1),
              child: Icon(_getCategoryIcon(type), color: _getCategoryColor(type)),
            ),
            title: Text('${n['message']}', maxLines: 2),
            subtitle: Text(
              DateTime.parse(n['created_at']).toLocal().toString().substring(0, 16),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: _asBool(n['is_read'])
                ? const Icon(Icons.done_all, color: Colors.green, size: 16)
                : TextButton(onPressed: () => _markRead(n['id']), child: const Text('Mark Read')),
          ),
        );
      },
    );
  }
}
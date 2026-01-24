import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/caregiver_api.dart';

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  final _api = CaregiverApi();
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _active;
  List<Map<String, dynamic>> _history = [];

  String _fmt(dynamic v) {
    if (v == null) return '-';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return v.toString();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final active = await _api.getMyActiveShift();
      final history = await _api.getMyShiftHistory(limit: 50);
      if (mounted) {
        setState(() {
          _active = active;
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _showShiftDialog({required bool starting}) async {
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(starting ? 'Start New Shift' : 'End Active Shift'),
        content: TextField(
          controller: notes,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add notes for this shift...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: starting ? Colors.green : Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(starting ? 'Clock In' : 'Clock Out'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      if (starting) {
        await _api.startMyShift(notes: notes.text.trim().isEmpty ? null : notes.text.trim());
      } else {
        await _api.endMyShift(notes: notes.text.trim().isEmpty ? null : notes.text.trim());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(starting ? 'Shift started ✅' : 'Shift ended ✅'), behavior: SnackBarBehavior.floating),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorState(cs, tt);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildActiveShiftCard(cs, tt),
          const SizedBox(height: 32),
          Text('Shift History', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_history.isEmpty) _buildEmptyHistory(cs, tt) else ..._history.map((s) => _buildHistoryCard(s, cs, tt)),
        ],
      ),
    );
  }

  Widget _buildActiveShiftCard(ColorScheme cs, TextTheme tt) {
    final bool hasActive = _active != null;
    final Color cardColor = hasActive ? Colors.green.withOpacity(0.1) : cs.surfaceVariant.withOpacity(0.3);
    final Color accentColor = hasActive ? Colors.green : cs.secondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasActive ? Icons.timer : Icons.timer_off_outlined, color: accentColor),
              const SizedBox(width: 12),
              Text(hasActive ? 'Current Active Shift' : 'Off Duty',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: accentColor)),
            ],
          ),
          const SizedBox(height: 20),
          if (hasActive) ...[
            Text('Started at', style: tt.bodySmall?.copyWith(color: Colors.grey[600])),
            Text(_fmt(_active!['shift_start']), style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(_active!['home_name'] ?? 'Not specified', style: tt.bodyMedium),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showShiftDialog(starting: false),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('End Shift & Clock Out'),
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.all(16)),
              ),
            ),
          ] else ...[
            Text('You are not currently on an active shift.', style: tt.bodyMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showShiftDialog(starting: true),
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Start New Shift'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> s, ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeChip(Icons.login, _fmt(s['shift_start']), Colors.blue),
              _buildTimeChip(Icons.logout, _fmt(s['shift_end']), Colors.orange),
            ],
          ),
          if (s['notes'] != null && s['notes'].toString().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(s['notes'], style: tt.bodySmall?.copyWith(fontStyle: FontStyle.italic))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyHistory(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: cs.outline),
            const SizedBox(height: 16),
            const Text('No previous shifts found.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text('Failed to sync shifts', style: tt.titleMedium),
          Text(_error ?? 'Unknown error', style: tt.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextButton(onPressed: _load, child: const Text('Retry Connection')),
        ],
      ),
    );
  }
}
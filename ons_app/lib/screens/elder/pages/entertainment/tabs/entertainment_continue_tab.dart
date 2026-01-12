import 'package:flutter/material.dart';

import 'package:ons_app/services/elder_entertainment_api.dart.dart';
import '../widgets/entertainment_item_card.dart';

class EntertainmentContinueTab extends StatefulWidget {
  const EntertainmentContinueTab({super.key});

  @override
  State<EntertainmentContinueTab> createState() => _EntertainmentContinueTabState();
}

class _EntertainmentContinueTabState extends State<EntertainmentContinueTab> {
  final api = ElderEntertainmentApi();

  bool loading = true;
  String? error;

  List<dynamic> cont = [];
  List<dynamic> favorites = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        api.getContinue(),
        api.getFavorites(),
      ]);
      cont = results[0] as List<dynamic>;
      favorites = results[1] as List<dynamic>;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int _idOf(dynamic x) {
    if (x is Map && x['item_id'] != null) {
      final v = x['item_id'];
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }
    return 0;
  }

  bool _isFav(int itemId) => favorites.any((f) => _idOf(f) == itemId);

  void _snack(String msg) {
    final m = msg.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    final id = _idOf(item);
    if (id == 0) return;

    try {
      if (_isFav(id)) {
        await api.removeFavorite(id);
      } else {
        await api.addFavorite(id);
      }
      favorites = await api.getFavorites();
      if (mounted) setState(() {});
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _saveActivity(Map<String, dynamic> item) async {
    final id = _idOf(item);
    if (id == 0) return;

    try {
      await api.upsertActivity(
        itemId: id,
        activityType: 'watched',
        status: 'ongoing',
        progressPercent: 50,
      );
      _snack('Activity saved ✅');
    } catch (e) {
      _snack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));
    if (cont.isEmpty) return const Center(child: Text('Nothing to continue yet.'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: cont.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final raw = cont[i];
          final item = (raw is Map<String, dynamic>)
              ? raw
              : Map<String, dynamic>.from(raw as Map);

          final id = _idOf(item);

          return EntertainmentItemCard(
            item: item,
            isFavorite: _isFav(id),
            onToggleFavorite: () => _toggleFavorite(item),
            onSaveProgress: () => _saveActivity(item),
          );
        },
      ),
    );
  }
}

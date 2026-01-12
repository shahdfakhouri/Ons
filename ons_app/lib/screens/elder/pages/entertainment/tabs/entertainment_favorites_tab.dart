import 'package:flutter/material.dart';

import 'package:ons_app/services/elder_entertainment_api.dart.dart';
import '../widgets/entertainment_item_card.dart';

class EntertainmentFavoritesTab extends StatefulWidget {
  const EntertainmentFavoritesTab({super.key});

  @override
  State<EntertainmentFavoritesTab> createState() => _EntertainmentFavoritesTabState();
}

class _EntertainmentFavoritesTabState extends State<EntertainmentFavoritesTab> {
  final api = ElderEntertainmentApi();

  bool loading = true;
  String? error;

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
      favorites = await api.getFavorites();
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

  void _snack(String msg) {
    final m = msg.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _removeFavorite(Map<String, dynamic> item) async {
    final id = _idOf(item);
    if (id == 0) return;

    try {
      await api.removeFavorite(id);
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
        progressPercent: 10,
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
    if (favorites.isEmpty) return const Center(child: Text('No favorites yet.'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final raw = favorites[i];
          final item = (raw is Map<String, dynamic>)
              ? raw
              : Map<String, dynamic>.from(raw as Map);

          return EntertainmentItemCard(
            item: item,
            isFavorite: true,
            onToggleFavorite: () => _removeFavorite(item),
            onSaveProgress: () => _saveActivity(item),
          );
        },
      ),
    );
  }
}

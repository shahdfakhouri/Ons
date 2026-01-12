import 'package:flutter/material.dart';

class EntertainmentItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onSaveProgress;

  const EntertainmentItemCard({
    super.key,
    required this.item,
    required this.isFavorite,
    this.onToggleFavorite,
    this.onSaveProgress,
  });

  int get itemId {
    final v = item['item_id'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String get title => (item['title'] ?? 'Untitled').toString();
  String get type => (item['type'] ?? '').toString();
  String get provider => (item['provider'] ?? '').toString();
  String get thumb => (item['thumbnail_url'] ?? '').toString();

  double? get progress {
    final v = item['progress_percent'];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String get status => (item['status'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: thumb.isEmpty
                ? const Icon(Icons.play_circle_outline)
                : Image.network(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                if (type.isNotEmpty) type,
                if (provider.isNotEmpty) provider,
                if (status.isNotEmpty) 'status: $status',
                if (progress != null) 'progress: ${progress!.toStringAsFixed(0)}%',
              ].join(' • '),
            ),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: LinearProgressIndicator(
                  value: (progress!.clamp(0, 100)) / 100,
                ),
              ),
          ],
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            IconButton(
              tooltip: 'Favorite',
              onPressed: (itemId == 0) ? null : onToggleFavorite,
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              color: isFavorite ? Colors.redAccent : null,
            ),
            IconButton(
              tooltip: 'Save activity',
              onPressed: (itemId == 0) ? null : onSaveProgress,
              icon: const Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }
}

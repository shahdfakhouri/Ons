import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';
import 'package:ons_app/core/constants/api_config.dart';

class ElderGalleryPage extends StatefulWidget {
  final int elderId;
  const ElderGalleryPage({super.key, required this.elderId});

  @override
  State<ElderGalleryPage> createState() => _ElderGalleryPageState();
}

class _ElderGalleryPageState extends State<ElderGalleryPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  Future<void> _delete(int mediaId) async {
    try {
      await api.deleteGalleryMedia(mediaId);
      if (!mounted) return;
      showSnack(context, 'Deleted ✅');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elderId = widget.elderId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder(
        future: api.getElderGallery(elderId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final list = (data['gallery'] as List?) ?? const [];

          if (list.isEmpty) {
            return const EmptyState(
              title: 'No media yet',
              subtitle: 'Upload UI needs file picker + multipart. For now you can view/delete existing media.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = list[i] as Map;
              final mediaId = (m['media_id'] ?? 0) as int? ?? 0;
              final path = (m['file_path'] ?? '').toString();
              final caption = (m['caption'] ?? '').toString();
              final url = '${ApiConfig.baseUrl}$path';

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.photo),
                  title: Text(caption.isEmpty ? 'Media #$mediaId' : caption, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(url),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _delete(mediaId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


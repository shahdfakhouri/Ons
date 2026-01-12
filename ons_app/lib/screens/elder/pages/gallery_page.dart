import 'package:flutter/material.dart';
import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/utils/pick_file.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      items = await api.gallery();
      setState(() => loading = false);
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _upload() async {
    final picked = await pickFileBytes();
    if (picked == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload supported on Web (Chrome) only for now')));
      return;
    }

    try {
      await api.uploadMedia(bytes: picked.bytes, filename: picked.filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded ✅')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _delete(dynamic e) async {
    final id = e['media_id'] ?? e['id'];
    if (id == null) return;
    try {
      await api.deleteMedia(int.parse('$id'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted ✅')));
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _upload, icon: const Icon(Icons.upload)),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No media yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final e = items[i] as Map;
                final filePath = e['file_path']?.toString() ?? '';
                final url = filePath.startsWith('http')
                    ? filePath
                    : '${ApiConfig.baseUrl}$filePath';

                final mediaId = e['media_id']?.toString() ?? '';
                return InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((e['media_type']?.toString() ?? 'photo') == 'video')
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text('Video: $url'),
                            )
                          else
                            Image.network(url, fit: BoxFit.cover),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ID: $mediaId'),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _delete(e);
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                );
              },
            ),
    );
  }
}

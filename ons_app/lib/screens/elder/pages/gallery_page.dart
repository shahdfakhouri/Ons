import 'package:flutter/material.dart';
import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/utils/pick_file.dart';

class GalleryPage extends StatefulWidget {
  // ✅ 1. Accept the onBack navigation callback
  final void Function(int index)? onBack;
  const GalleryPage({super.key, this.onBack});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  // Colors aligned with your ONS palette
  static const _deepNavy = Color(0xFF313647);
  static const _cream = Color(0xFFF9F9F4);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ 2. Helper to return to Index 0 (Home)
  void _triggerBack() {
    if (widget.onBack != null) {
      widget.onBack!(0);
    }
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      items = await api.gallery();
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _upload() async {
    final picked = await pickFileBytes();
    if (picked == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload supported on Web (Chrome) only for now'))
      );
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
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(body: Center(child: Text('Error: $error')));

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    // ✅ 3. PopScope intercepts the device back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          // ✅ 4. Manual back button navigation
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _deepNavy),
            onPressed: _triggerBack,
          ),
          title: const Text('My Gallery', style: TextStyle(fontWeight: FontWeight.bold, color: _deepNavy)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: _deepNavy)),
            IconButton(onPressed: _upload, icon: const Icon(Icons.add_photo_alternate_rounded, color: _deepNavy)),
          ],
        ),
        body: items.isEmpty
            ? const Center(child: Text('No memories shared yet.', style: TextStyle(color: Colors.grey)))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 4, // 2 columns on phone, 4 on web
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i] as Map;
                  final filePath = e['file_path']?.toString() ?? '';
                  final url = filePath.startsWith('http') ? filePath : '${ApiConfig.baseUrl}$filePath';

                  return InkWell(
                    onTap: () => _showFullImage(e, url),
                    child: Hero(
                      tag: 'media_$i',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            url, 
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showFullImage(Map e, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: (e['media_type']?.toString() ?? 'photo') == 'video'
                  ? AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                      ),
                    )
                  : Image.network(url, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Shared Memory", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _delete(e);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
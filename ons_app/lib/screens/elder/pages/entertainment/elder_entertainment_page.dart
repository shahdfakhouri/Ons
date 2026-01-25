import 'package:flutter/material.dart';

import 'tabs/entertainment_continue_tab.dart';
import 'tabs/entertainment_favorites_tab.dart';
import 'tabs/entertainment_feed_tab.dart';
import 'tabs/entertainment_history_tab.dart';

class ElderEntertainmentPage extends StatefulWidget {
  // ✅ 1. Accept the onBack navigation callback
  final void Function(int index)? onBack;
  const ElderEntertainmentPage({super.key, this.onBack});

  @override
  State<ElderEntertainmentPage> createState() => _ElderEntertainmentPageState();
}

class _ElderEntertainmentPageState extends State<ElderEntertainmentPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  // Colors aligned with your ONS palette
  static const _deepNavy = Color(0xFF313647);
  static const _sage = Color(0xFFA3B087);

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
  }

  // ✅ 2. Helper to return to Index 0 (Home)
  void _triggerBack() {
    if (widget.onBack != null) {
      widget.onBack!(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 3. PopScope intercepts the device back button to prevent app exit
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        appBar: AppBar(
          // ✅ 4. Manual back button navigation
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _deepNavy),
            onPressed: _triggerBack,
          ),
          title: const Text('Entertainment', 
            style: TextStyle(fontWeight: FontWeight.bold, color: _deepNavy)
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _controller,
            labelColor: _deepNavy,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _sage,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.explore), text: 'Feed'),
              Tab(icon: Icon(Icons.play_circle), text: 'Continue'),
              Tab(icon: Icon(Icons.favorite), text: 'Likes'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(), // Prevent accidental swipes
          children: const [
            EntertainmentFeedTab(),
            EntertainmentContinueTab(),
            EntertainmentFavoritesTab(),
            EntertainmentHistoryTab(),
          ],
        ),
      ),
    );
  }
}